// Datos de prueba de Operación: dispositivos, flujo, respuesta parcial y 403
// de consola (US20, US29, US32, TS10, TS17).
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/app/mocks/iam/mock_auth_datasource.dart';
import 'package:quadrapp_mobile/app/mocks/mock_console_json.dart';
import 'package:quadrapp_mobile/app/mocks/mock_controls.dart';
import 'package:quadrapp_mobile/app/mocks/mock_world.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/dto/auth_dtos.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/test_seed.dart';

MockWorld newWorld({MockControls? controls, FakeClock? clock}) => MockWorld(
  seed: testSeed,
  clock: clock ?? FakeClock(),
  controls: controls,
  random: Random(1),
  latency: false,
);

Future<int?> statusOf(Future<void> Function() call) async {
  try {
    await call();
    return null;
  } on DioException catch (error) {
    return error.response?.statusCode;
  }
}

void main() {
  group('dispositivos de la semilla', () {
    test('cada lote tiene su inventario y los identificadores son únicos', () {
      final world = newWorld();

      expect(
        [for (final lot in world.lots) world.devicesOf(lot.id).length],
        [123, 83, 1, 151],
      );
      final hardwareIds = world.devices.map((d) => d.hardwareId).toSet();
      expect(hardwareIds.length, world.devices.length);
      expect(
        world.devices.map((d) => d.id).toSet().length,
        world.devices.length,
      );
    });

    test('el estado de cada sensor es coherente con el de su espacio '
        '(TS10 esc. 2 y 3)', () {
      final world = newWorld();

      for (final lot in world.lots) {
        final bySpace = {
          for (final device in world.devicesOf(lot.id))
            if (device.spaceId != null) device.spaceId!: device,
        };
        for (final space in lot.spaces) {
          final device = bySpace[space.id];
          switch (space.unknownReason) {
            case 'LOW_BATTERY':
              expect(device?.status, 'LOW_BATTERY', reason: space.label);
              expect(device!.batteryPct, lessThan(15));
            case 'NO_HEARTBEAT':
              expect(device?.status, 'UNREACHABLE', reason: space.label);
            case 'NO_SENSOR':
              // Sin sensor operativo: el dado de baja queda como historial.
              expect(device?.status, 'DECOMMISSIONED', reason: space.label);
            default:
              expect(device?.status, 'OPERATIONAL', reason: space.label);
          }
        }
      }
    });

    test(
      'el sensor de paso es direccional y los gateways no tienen espacio',
      () {
        final world = newWorld();

        for (final device in world.devices) {
          if (device.type == 'PASS_SENSOR') expect(device.directional, isTrue);
          if (device.type == 'GATEWAY') expect(device.spaceId, isNull);
        }
        expect(
          world.devicesOf(3).single.status,
          'UNREACHABLE',
          reason: 'San Miguel no tiene distribución y su gateway no responde',
        );
      },
    );

    test('la última comunicación se resuelve contra la hora de carga', () {
      final clock = FakeClock();
      final world = newWorld(clock: clock);
      final unreachable = world.devices.firstWhere(
        (d) => d.status == 'UNREACHABLE' && d.type == 'SPACE_SENSOR',
      );

      expect(
        clock.now().difference(unreachable.lastSeen!),
        greaterThan(const Duration(hours: 2)),
      );
    });

    test('registrar da un dispositivo operativo sin espacio; dar de baja lo '
        'deja como historial; restablecer vuelve a la semilla', () {
      final world = newWorld();
      final before = world.devicesOf(1).length;

      final created = world.registerDevice(
        lotId: 1,
        type: 'PASS_SENSOR',
        hardwareId: 'PASS-L1-99',
        expectedReportIntervalSec: 60,
        directional: false,
      );
      expect(created.status, 'OPERATIONAL');
      expect(created.spaceId, isNull);
      expect(world.hardwareIdTaken('PASS-L1-99'), isTrue);
      expect(world.devicesOf(1).length, before + 1);

      expect(world.decommissionDevice(created.id), isTrue);
      expect(created.status, 'DECOMMISSIONED');
      expect(world.devicesOf(1).length, before + 1);
      expect(world.decommissionDevice(999999), isFalse);

      world.reset();
      expect(world.devicesOf(1).length, before);
      expect(world.hardwareIdTaken('PASS-L1-99'), isFalse);
    });
  });

  group('GET /console/overview', () {
    test('el lote normal: cifras, flujo y sin saturación', () {
      final world = newWorld();

      final json = mockOverviewJson(world, world.lot(1)!);

      expect(json['lotId'], 1);
      expect(
        [json['capacity'], json['free'], json['occupied'], json['unknown']],
        [120, 45, 72, 3],
      );
      expect(json['flow'], {'entries': 12, 'exits': 9, 'windowMin': 15});
      expect(json['saturation'], isNull);
      expect(json['stale'], isFalse);
      expect(json['unavailable'], isEmpty);
      expect(
        json.keys,
        containsAll([
          'serverTime',
          'consolidatedAt',
          'staleAfterSeconds',
          'stale',
          'unavailable',
        ]),
      );
    });

    test('el lote casi lleno prevé la saturación en 25 minutos', () {
      final clock = FakeClock();
      final world = newWorld(clock: clock);

      final json = mockOverviewJson(world, world.lot(2)!);

      final saturation = json['saturation']! as Map<String, Object?>;
      expect(
        DateTime.parse(saturation['expectedAt']! as String),
        clock.now().add(const Duration(minutes: 25)),
      );
      expect(saturation['pct'], greaterThanOrEqualTo(90));
      expect(json['flow'], {'entries': 4, 'exits': 1, 'windowMin': 15});
    });

    test('el lote vencido: stale, sin flujo y con la saturación no disponible '
        '(respuesta parcial, TS17 esc. 3)', () {
      final world = newWorld();

      final json = mockOverviewJson(world, world.lot(4)!);

      expect(json['stale'], isTrue);
      expect(json['flow'], isNull);
      expect(json['saturation'], isNull);
      expect(json['unavailable'], ['saturation']);
    });

    test('el interruptor de respuesta parcial quita la saturación de '
        'cualquier lote y la lista en unavailable', () {
      final controls = MockControls()..forceConsolePartial = true;
      final world = newWorld(controls: controls);

      final json = mockOverviewJson(world, world.lot(2)!);

      expect(json['saturation'], isNull);
      expect(json['unavailable'], ['saturation']);
      expect(json['free'], 0, reason: 'el estado actual sigue llegando');
    });
  });

  group('GET /devices/health', () {
    test('trae serverTime y cada dispositivo con la forma de docs/07', () {
      final world = newWorld();

      final json = mockDevicesHealthJson(world, world.lot(1)!);

      expect(json['serverTime'], isA<String>());
      final devices = (json['devices']! as List).cast<Map<String, Object?>>();
      expect(devices, hasLength(123));
      final lowBattery = devices.firstWhere(
        (d) => d['status'] == 'LOW_BATTERY',
      );
      expect(lowBattery['spaceLabel'], 'A-18');
      expect(lowBattery['type'], 'SPACE_SENSOR');
      expect(
        lowBattery.keys,
        containsAll([
          'id',
          'hardwareId',
          'type',
          'status',
          'batteryPct',
          'lastSeenAt',
          'expectedReportIntervalSec',
        ]),
      );
      final gateway = devices.firstWhere((d) => d['type'] == 'GATEWAY');
      expect(gateway.containsKey('batteryPct'), isFalse);
      expect(gateway.containsKey('spaceLabel'), isFalse);
    });
  });

  group('403 de consola (TS17 esc. 2)', () {
    test('un conductor recibe 403; Operación pasa', () async {
      final world = newWorld();

      expect(await statusOf(() => world.gateConsole('DRIVER')), 403);
      expect(await statusOf(() => world.gateConsole('ADMIN')), isNull);
      expect(await statusOf(() => world.gateConsole('OPERATOR')), isNull);
    });

    test('sin rol es 401 y el interruptor fuerza el 403 para todos', () async {
      final controls = MockControls();
      final world = newWorld(controls: controls);

      expect(await statusOf(() => world.gateConsole(null)), 401);
      controls.forceConsole403 = true;
      expect(await statusOf(() => world.gateConsole('ADMIN')), 403);
    });
  });

  group('rol por token y nombre completo', () {
    Future<LoginResponseDto> login(MockWorld world, String email) async {
      final auth = MockAuthRemoteDataSource(world);
      await auth.requestOtp(OtpRequestDto(email: email));
      return auth.login(LoginRequestDto(email: email, code: '123456'));
    }

    test(
      'el login trae el nombre del conductor y ninguno del administrador',
      () async {
        final world = newWorld();

        final driver = await login(world, 'conductor@upc.edu.pe');
        final admin = await login(world, 'administrador@upc.edu.pe');

        expect(driver.user.fullName, 'Camila Rojas');
        expect(admin.user.fullName, isNull);
      },
    );

    test('cada token recuerda el rol con el que se emitió, también al '
        'refrescar', () async {
      final world = newWorld();

      final driver = await login(world, 'conductor@upc.edu.pe');
      final admin = await login(world, 'administrador@upc.edu.pe');
      final refreshed = await MockAuthRemoteDataSource(
        world,
      ).refresh(RefreshTokenRequestDto(refreshToken: admin.refreshToken));

      expect(world.iam.roleForAccessToken(driver.accessToken), 'DRIVER');
      expect(world.iam.roleForAccessToken(admin.accessToken), 'ADMIN');
      expect(world.iam.roleForAccessToken(refreshed.accessToken), 'ADMIN');
      expect(world.iam.roleForAccessToken('otro'), isNull);
    });
  });
}

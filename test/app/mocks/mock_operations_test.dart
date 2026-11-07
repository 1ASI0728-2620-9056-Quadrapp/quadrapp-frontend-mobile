// Los mocks de Operación, de punta a punta por los repositorios reales: el
// 403 a un conductor (TS17 esc. 2) y el registro y baja de dispositivos.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/app/mocks/mock_controls.dart';
import 'package:quadrapp_mobile/app/mocks/mock_world.dart';
import 'package:quadrapp_mobile/app/mocks/parking_sensing/mock_device_datasources.dart';
import 'package:quadrapp_mobile/app/mocks/shift/mock_shift_datasource.dart';
import 'package:quadrapp_mobile/composition/shift/shift_overview_mapper.dart';
import 'package:quadrapp_mobile/composition/shift/shift_overview_reader_impl.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/infrastructure/mappers/device_mapper.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/infrastructure/repositories/device_reader_impl.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/infrastructure/repositories/device_registry_impl.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/parking_sensing.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/recording_logger.dart';
import '../../helpers/test_seed.dart';

class _Suite {
  _Suite({MockControls? controls, String? role = 'ADMIN'})
    : controls = controls ?? MockControls(),
      callerRole = role {
    world = MockWorld(
      seed: testSeed,
      clock: clock,
      controls: this.controls,
      random: Random(1),
      latency: false,
    );
    final logger = RecordingLogger();
    final remote = MockDeviceRemoteDataSource(world, () => callerRole);
    reader = DeviceReaderImpl(
      remote: remote,
      mapper: DeviceMapper(logger),
      clock: clock,
    );
    registry = DeviceRegistryImpl(remote: remote, mapper: DeviceMapper(logger));
    overview = ShiftOverviewReaderImpl(
      remote: MockShiftOverviewRemoteDataSource(world, () => callerRole),
      mapper: ShiftOverviewMapper(logger),
      clock: clock,
    );
  }

  final FakeClock clock = FakeClock();
  final MockControls controls;
  String? callerRole;
  late final MockWorld world;
  late final DeviceReaderImpl reader;
  late final DeviceRegistryImpl registry;
  late final ShiftOverviewReaderImpl overview;
}

NewDevice _device({
  String id = 'QS-L1-NEW',
  DeviceType type = DeviceType.spaceSensor,
  bool? directional,
}) => NewDevice.create(
  lotId: const LotId(1),
  type: type,
  hardwareId: id,
  expectedReportIntervalSec: 60,
  directional: directional,
).valueOrNull!;

void main() {
  group('403 de consola', () {
    test('un conductor no recibe ni el resumen ni los dispositivos', () async {
      final suite = _Suite(role: 'DRIVER');

      expect(
        (await suite.overview.read(const LotId(1))).failureOrNull,
        isA<ForbiddenFailure>(),
      );
      expect(
        (await suite.reader.read(const LotId(1))).failureOrNull,
        isA<ForbiddenFailure>(),
      );
      expect(
        (await suite.registry.register(_device())).failureOrNull,
        isA<ForbiddenFailure>(),
      );
      expect(
        (await suite.registry.decommission(const DeviceId(1))).failureOrNull,
        isA<ForbiddenFailure>(),
      );
      expect(suite.world.hardwareIdTaken('QS-L1-NEW'), isFalse);
    });

    test('ADMIN y OPERATOR ven lo mismo', () async {
      for (final role in ['ADMIN', 'OPERATOR']) {
        final suite = _Suite(role: role);

        expect((await suite.overview.read(const LotId(1))).isSuccess, isTrue);
        expect((await suite.reader.read(const LotId(1))).isSuccess, isTrue);
      }
    });

    test(
      'sin sesión es 401 y el interruptor fuerza el 403 a Operación',
      () async {
        final controls = MockControls();
        final suite = _Suite(controls: controls, role: null);
        expect(
          (await suite.overview.read(const LotId(1))).failureOrNull,
          isA<UnauthorizedFailure>(),
        );

        suite.callerRole = 'ADMIN';
        controls.forceConsole403 = true;
        expect(
          (await suite.overview.read(const LotId(1))).failureOrNull,
          isA<ForbiddenFailure>(),
        );
      },
    );
  });

  group('GET /console/overview', () {
    test('San Miguel, sin distribución, responde 404', () async {
      final suite = _Suite();

      expect(
        (await suite.overview.read(const LotId(3))).failureOrNull,
        isA<NotFoundFailure>(),
      );
    });

    test('Villa llega vencida y con la saturación no '
        'disponible', () async {
      final suite = _Suite();

      final overview = (await suite.overview.read(const LotId(4))).valueOrNull!;

      expect(overview.freshness.isStale(suite.clock), isTrue);
      expect(overview.saturationUnavailable, isTrue);
      expect(overview.flow, isNull);
    });

    test('San Isidro prevé saturación y tiene flujo', () async {
      final suite = _Suite();

      final overview = (await suite.overview.read(const LotId(2))).valueOrNull!;

      expect(overview.saturation, isNotNull);
      expect(overview.flow?.exits, 1);
      expect(overview.occupancyFraction, 1);
    });
  });

  group('dispositivos', () {
    test('la salud trae el inventario con sus estados', () async {
      final suite = _Suite();

      final inv = (await suite.reader.read(const LotId(1))).valueOrNull!;

      expect(inv.devices, hasLength(123));
      expect(inv.attentionCount, 2);
      expect(inv.countOf(DeviceStatus.decommissioned), 1);
      final lowBattery = inv.where(status: DeviceStatus.lowBattery).single;
      expect(lowBattery.spaceLabel, 'A-18');
    });

    test('registrar un sensor de paso suma al inventario; un identificador '
        'repetido da 409', () async {
      final suite = _Suite();

      final created = await suite.registry.register(
        _device(
          id: 'PASS-L1-03',
          type: DeviceType.passSensor,
          directional: true,
        ),
      );
      expect(created.valueOrNull?.status, DeviceStatus.operational);
      expect(created.valueOrNull?.directional, isTrue);
      expect(
        (await suite.reader.read(const LotId(1))).valueOrNull?.devices,
        hasLength(124),
      );

      final duplicate = await suite.registry.register(
        _device(
          id: 'PASS-L1-03',
          type: DeviceType.passSensor,
          directional: false,
        ),
      );
      final failure = duplicate.failureOrNull! as ValidationFailure;
      expect(failure.errors, contains('hardwareId'));
    });

    test(
      'el interruptor hace fallar el registro con un error del servidor',
      () async {
        final controls = MockControls()..forceDeviceRegisterFailure = true;
        final suite = _Suite(controls: controls);

        final result = await suite.registry.register(_device());

        expect(result.failureOrNull, isA<ServerFailure>());
        expect(suite.world.hardwareIdTaken('QS-L1-NEW'), isFalse);
      },
    );

    test('dar de baja deja el dispositivo como historial; repetirlo no '
        'falla', () async {
      final suite = _Suite();
      final target = (await suite.reader.read(const LotId(1)))
          .valueOrNull!
          .devices
          .firstWhere(
            (d) => d.isOperational && d.type == DeviceType.spaceSensor,
          );

      expect((await suite.registry.decommission(target.id)).isSuccess, isTrue);
      final after = (await suite.reader.read(const LotId(1))).valueOrNull!;
      expect(
        after.devices.firstWhere((d) => d.id == target.id).status,
        DeviceStatus.decommissioned,
      );
      expect(after.devices, hasLength(123));
      expect((await suite.registry.decommission(target.id)).isSuccess, isTrue);
      expect(
        (await suite.registry.decommission(const DeviceId(999999))).isSuccess,
        isTrue,
        reason: 'un 404 al dar de baja es éxito',
      );
    });
  });
}

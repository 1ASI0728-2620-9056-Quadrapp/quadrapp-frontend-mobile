// US20, US32, TS10: DTOs, mapper y repositorios de dispositivos (los casos
// clave: caso feliz, error de red y valor desconocido del servidor).
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/app/mocks/mock_errors.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/infrastructure/datasources/device_remote_datasource.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/infrastructure/dto/device_dtos.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/infrastructure/mappers/device_mapper.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/infrastructure/repositories/device_reader_impl.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/infrastructure/repositories/device_registry_impl.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/parking_sensing.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/recording_logger.dart';
import 'support.dart';

class _FakeRemote implements DeviceRemoteDataSource {
  Future<DeviceHealthDto> Function() onHealth = () async =>
      DeviceHealthDto.fromJson(healthJson());
  Future<DeviceDto> Function(RegisterDeviceRequestDto) onRegister = (_) async =>
      DeviceDto.fromJson(deviceJson(9));
  Future<void> Function(DeviceId) onDecommission = (_) async {};
  RegisterDeviceRequestDto? lastRequest;

  @override
  Future<DeviceHealthDto> health(LotId lotId) => onHealth();

  @override
  Future<DeviceDto> register(RegisterDeviceRequestDto request) {
    lastRequest = request;
    return onRegister(request);
  }

  @override
  Future<void> decommission(DeviceId id) => onDecommission(id);
}

void main() {
  late RecordingLogger logger;
  late DeviceMapper mapper;
  late _FakeRemote remote;

  setUp(() {
    logger = RecordingLogger();
    mapper = DeviceMapper(logger);
    remote = _FakeRemote();
  });

  group('DeviceMapper', () {
    test('caso feliz: el inventario con la hora del servidor', () {
      final inv = mapper.toInventory(
        DeviceHealthDto.fromJson(healthJson()),
        const LotId(1),
        receivedAt: const Duration(seconds: 3),
      );

      expect(inv.devices, hasLength(3));
      expect(inv.serverTime, serverTime);
      expect(inv.receivedAt, const Duration(seconds: 3));
      final lowBattery = inv.devices[1];
      expect(lowBattery.status, DeviceStatus.lowBattery);
      expect(lowBattery.batteryPct, 9);
      expect(lowBattery.spaceLabel, 'A-18');
      expect(lowBattery.lastSeenAt, DateTime.utc(2026, 9, 28, 13, 41, 40));
      expect(lowBattery.expectedReportInterval, const Duration(seconds: 60));
      final gateway = inv.devices[2];
      expect(gateway.type, DeviceType.gateway);
      expect(gateway.batteryPct, isNull);
      expect(gateway.spaceLabel, isNull);
      expect(logger.messages, isEmpty);
    });

    test('un estado desconocido es UNREACHABLE y deja un aviso sin datos '
        'personales', () {
      final inv = mapper.toInventory(
        DeviceHealthDto.fromJson(
          healthJson(devices: [deviceJson(1, status: 'EXPLODED')]),
        ),
        const LotId(1),
        receivedAt: Duration.zero,
      );

      expect(inv.devices.single.status, DeviceStatus.unreachable);
      expect(logger.messages, hasLength(1));
      expect(logger.messages.single, isNot(contains('QS-L1')));
    });

    test('un tipo desconocido se omite de la lista y deja un aviso', () {
      final inv = mapper.toInventory(
        DeviceHealthDto.fromJson(
          healthJson(
            devices: [
              deviceJson(1),
              deviceJson(2, type: 'DRONE'),
            ],
          ),
        ),
        const LotId(1),
        receivedAt: Duration.zero,
      );

      expect(inv.devices.map((d) => d.id.value), [1]);
      expect(logger.messages, hasLength(1));
    });

    test('los estados y tipos se leen sin distinguir mayúsculas', () {
      expect(mapper.parseStatus('low_battery'), DeviceStatus.lowBattery);
      expect(mapper.parseType('gateway'), DeviceType.gateway);
      expect(logger.messages, isEmpty);
    });

    test('el cuerpo de POST /devices lleva directional solo en un sensor de '
        'paso', () {
      final pass = NewDevice.create(
        lotId: const LotId(1),
        type: DeviceType.passSensor,
        hardwareId: 'PASS-L1-03',
        expectedReportIntervalSec: 30,
        directional: true,
      ).valueOrNull!;
      final gateway = NewDevice.create(
        lotId: const LotId(1),
        type: DeviceType.gateway,
        hardwareId: 'GW-L1-02',
        expectedReportIntervalSec: 60,
      ).valueOrNull!;

      expect(mapper.toRequest(pass).toJson(), {
        'lotId': 1,
        'type': 'PASS_SENSOR',
        'hardwareId': 'PASS-L1-03',
        'expectedReportIntervalSec': 30,
        'directional': true,
      });
      expect(
        mapper.toRequest(gateway).toJson().containsKey('directional'),
        isFalse,
      );
    });
  });

  group('DeviceReaderImpl', () {
    DeviceReaderImpl reader(FakeClock clock) =>
        DeviceReaderImpl(remote: remote, mapper: mapper, clock: clock);

    test('lee el inventario con el reloj monótono al recibirlo', () async {
      final clock = FakeClock()..advance(const Duration(seconds: 7));

      final result = await reader(clock).read(const LotId(1));

      expect(result.valueOrNull?.devices, hasLength(3));
      expect(result.valueOrNull?.receivedAt, const Duration(seconds: 7));
    });

    test('sin red: NetworkFailure', () async {
      remote.onHealth = () async =>
          throw mockDioError(DioExceptionType.connectionError);

      final result = await reader(FakeClock()).read(const LotId(1));

      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('403 de un conductor: ForbiddenFailure', () async {
      remote.onHealth = () async => throw mockHttpError(403);

      final result = await reader(FakeClock()).read(const LotId(1));

      expect(result.failureOrNull, isA<ForbiddenFailure>());
    });

    test('una respuesta ilegible: ParseFailure', () async {
      remote.onHealth = () async => DeviceHealthDto.fromJson({
        'serverTime': 'ayer',
        'devices': const <Object?>[],
      });

      final result = await reader(FakeClock()).read(const LotId(1));

      expect(result.failureOrNull, isA<ParseFailure>());
    });
  });

  group('DeviceRegistryImpl', () {
    DeviceRegistryImpl registry() =>
        DeviceRegistryImpl(remote: remote, mapper: mapper);

    NewDevice newDevice() => NewDevice.create(
      lotId: const LotId(1),
      type: DeviceType.spaceSensor,
      hardwareId: 'QS-L1-9',
      expectedReportIntervalSec: 60,
    ).valueOrNull!;

    test(
      'registrar devuelve el dispositivo y envía el cuerpo del contrato',
      () async {
        final result = await registry().register(newDevice());

        expect(result.valueOrNull?.id, const DeviceId(9));
        expect(result.valueOrNull?.lotId, const LotId(1));
        expect(remote.lastRequest?.hardwareId, 'QS-L1-9');
      },
    );

    test('un identificador duplicado (409): ValidationFailure con '
        'hardwareId', () async {
      remote.onRegister = (_) async => throw mockHttpError(
        409,
        extra: {
          'errors': {
            'hardwareId': ['duplicate'],
          },
        },
      );

      final result = await registry().register(newDevice());

      final failure = result.failureOrNull! as ValidationFailure;
      expect(failure.errors, contains('hardwareId'));
    });

    test('un error del servidor (500): ServerFailure', () async {
      remote.onRegister = (_) async => throw mockHttpError(500);

      final result = await registry().register(newDevice());

      expect(result.failureOrNull, isA<ServerFailure>());
    });

    test(
      'dar de baja un dispositivo que ya no existe (404) es éxito',
      () async {
        remote.onDecommission = (_) async => throw mockHttpError(404);

        final result = await registry().decommission(const DeviceId(1));

        expect(result.isSuccess, isTrue);
      },
    );

    test('dar de baja sin red falla con NetworkFailure; con 403, '
        'ForbiddenFailure', () async {
      remote.onDecommission = (_) async =>
          throw mockDioError(DioExceptionType.connectionError);
      expect(
        (await registry().decommission(const DeviceId(1))).failureOrNull,
        isA<NetworkFailure>(),
      );

      remote.onDecommission = (_) async => throw mockHttpError(403);
      expect(
        (await registry().decommission(const DeviceId(1))).failureOrNull,
        isA<ForbiddenFailure>(),
      );
    });
  });
}

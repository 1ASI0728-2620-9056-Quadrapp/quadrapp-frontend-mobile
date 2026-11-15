// US20, US32, TS10: casos de uso de dispositivos.
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/domain/repositories/device_reader.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/domain/repositories/device_registry.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/parking_sensing.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

import 'support.dart';

class _MockReader extends Mock implements DeviceReader {}

class _MockRegistry extends Mock implements DeviceRegistry {}

void main() {
  late _MockReader reader;
  late _MockRegistry registry;

  NewDevice newDevice() => NewDevice.create(
    lotId: const LotId(1),
    type: DeviceType.gateway,
    hardwareId: 'GW-L1-02',
    expectedReportIntervalSec: 60,
  ).valueOrNull!;

  setUpAll(() {
    registerFallbackValue(const LotId(1));
    registerFallbackValue(const DeviceId(1));
    registerFallbackValue(newDevice());
  });

  setUp(() {
    reader = _MockReader();
    registry = _MockRegistry();
  });

  test(
    'GetDeviceInventory devuelve el inventario del estacionamiento',
    () async {
      final inv = inventory([device(1)]);
      when(() => reader.read(any())).thenAnswer((_) async => Success(inv));

      final result = await GetDeviceInventory(reader)(const LotId(1));

      expect(result.valueOrNull, inv);
      verify(() => reader.read(const LotId(1))).called(1);
    },
  );

  test('GetDeviceInventory propaga el 403 de un conductor', () async {
    when(
      () => reader.read(any()),
    ).thenAnswer((_) async => const Err(ForbiddenFailure()));

    final result = await GetDeviceInventory(reader)(const LotId(1));

    expect(result.failureOrNull, isA<ForbiddenFailure>());
  });

  test('RegisterDevice registra el dispositivo ya validado', () async {
    final created = device(9, type: DeviceType.gateway);
    when(
      () => registry.register(any()),
    ).thenAnswer((_) async => Success(created));

    final result = await RegisterDevice(registry)(newDevice());

    expect(result.valueOrNull, created);
    verify(() => registry.register(newDevice())).called(1);
  });

  test('RegisterDevice propaga el identificador duplicado', () async {
    when(() => registry.register(any())).thenAnswer(
      (_) async => const Err(
        ValidationFailure(null, {
          'hardwareId': ['duplicate'],
        }),
      ),
    );

    final result = await RegisterDevice(registry)(newDevice());

    expect(
      (result.failureOrNull! as ValidationFailure).errors,
      contains('hardwareId'),
    );
  });

  test('DecommissionDevice da de baja por su id', () async {
    when(
      () => registry.decommission(any()),
    ).thenAnswer((_) async => const Success<void>(null));

    final result = await DecommissionDevice(registry)(const DeviceId(7));

    expect(result.isSuccess, isTrue);
    verify(() => registry.decommission(const DeviceId(7))).called(1);
  });
}

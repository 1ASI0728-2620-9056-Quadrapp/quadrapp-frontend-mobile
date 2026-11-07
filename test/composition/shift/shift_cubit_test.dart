// US29, TS17, US20: la consola de turno.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quadrapp_mobile/composition/shift/get_shift_overview.dart';
import 'package:quadrapp_mobile/composition/shift/shift_console.dart';
import 'package:quadrapp_mobile/composition/shift/shift_cubit.dart';
import 'package:quadrapp_mobile/composition/shift/shift_overview.dart';
import 'package:quadrapp_mobile/contexts/occupancy/occupancy.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/parking_sensing.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

class _MockGetShiftOverview extends Mock implements GetShiftOverview {}

class _MockGetDeviceInventory extends Mock implements GetDeviceInventory {}

const LotId _lot = LotId(1);

ShiftOverview _overview({Set<ShiftSection> unavailable = const {}}) =>
    ShiftOverview(
      lotId: _lot,
      capacity: 120,
      free: 45,
      occupied: 72,
      unknown: 3,
      freshness: Freshness(
        consolidatedAt: DateTime.utc(2026, 9, 28, 13, 41, 40),
        serverTime: DateTime.utc(2026, 9, 28, 13, 42),
        staleAfter: const Duration(seconds: 180),
        receivedAt: Duration.zero,
      ),
      unavailable: unavailable,
    );

Device _device(
  int id,
  DeviceType type,
  DeviceStatus status,
) => Device(
  id: DeviceId(id),
  lotId: _lot,
  hardwareId: 'HW-$id',
  type: type,
  status: status,
  expectedReportInterval: const Duration(minutes: 5),
);

DeviceInventory _inventory(List<Device> devices) => DeviceInventory(
  lotId: _lot,
  devices: devices,
  serverTime: DateTime.utc(2026, 9, 28, 13, 42),
  receivedAt: Duration.zero,
);

void main() {
  late _MockGetShiftOverview getOverview;
  late _MockGetDeviceInventory getInventory;

  setUpAll(() => registerFallbackValue(_lot));

  setUp(() {
    getOverview = _MockGetShiftOverview();
    getInventory = _MockGetDeviceInventory();
  });

  ShiftCubit build() => ShiftCubit(
    getShiftOverview: getOverview,
    getDeviceInventory: getInventory,
  );

  group('ShiftCubit', () {
    blocTest<ShiftCubit, ViewState<ShiftConsole>>(
      'con todo, la consola completa',
      setUp: () {
        when(() => getOverview(any())).thenAnswer(
          (_) async => Success(_overview()),
        );
        when(() => getInventory(any())).thenAnswer(
          (_) async => Success(_inventory(const [])),
        );
      },
      build: build,
      act: (cubit) => cubit.load(_lot),
      expect: () => [
        const ViewLoading<ShiftConsole>(),
        ViewData(
          ShiftConsole(overview: _overview(), devices: _inventory(const [])),
        ),
      ],
    );

    blocTest<ShiftCubit, ViewState<ShiftConsole>>(
      'sin pronóstico ni dispositivos: parcial, con lo que falta',
      setUp: () {
        when(() => getOverview(any())).thenAnswer(
          (_) async =>
              Success(_overview(unavailable: {ShiftSection.saturation})),
        );
        when(() => getInventory(any())).thenAnswer(
          (_) async => const Err(NetworkFailure()),
        );
      },
      build: build,
      act: (cubit) => cubit.load(_lot),
      expect: () => [
        const ViewLoading<ShiftConsole>(),
        ViewPartial(
          ShiftConsole(
            overview: _overview(unavailable: {ShiftSection.saturation}),
          ),
          missing: const {'saturation', 'devices'},
        ),
      ],
    );

    blocTest<ShiftCubit, ViewState<ShiftConsole>>(
      'el 403 del servidor es un error, no una consola vacía (TS17 esc. 2)',
      setUp: () {
        when(() => getOverview(any())).thenAnswer(
          (_) async => const Err(ForbiddenFailure()),
        );
        when(() => getInventory(any())).thenAnswer(
          (_) async => const Err(ForbiddenFailure()),
        );
      },
      build: build,
      act: (cubit) => cubit.load(_lot),
      expect: () => [
        const ViewLoading<ShiftConsole>(),
        const ViewError<ShiftConsole>(ForbiddenFailure()),
      ],
    );
  });

  group('ShiftDeviceAlerts', () {
    test('gateways por separado; sensores agrupados; sin los de baja', () {
      final alerts = ShiftDeviceAlerts.from(
        _inventory([
          _device(1, DeviceType.gateway, DeviceStatus.unreachable),
          _device(2, DeviceType.spaceSensor, DeviceStatus.unreachable),
          _device(3, DeviceType.passSensor, DeviceStatus.unreachable),
          _device(4, DeviceType.spaceSensor, DeviceStatus.lowBattery),
          _device(5, DeviceType.spaceSensor, DeviceStatus.operational),
          _device(6, DeviceType.spaceSensor, DeviceStatus.decommissioned),
        ]),
      );

      expect(alerts.unreachableGateways.map((d) => d.hardwareId), ['HW-1']);
      expect(alerts.unreachableSensors, 2);
      expect(alerts.lowBatterySensors, 1);
      expect(alerts.isEmpty, isFalse);
    });

    test('sin inventario o todo operativo, no hay incidencias', () {
      expect(ShiftDeviceAlerts.from(null).isEmpty, isTrue);
      expect(
        ShiftDeviceAlerts.from(
          _inventory([
            _device(1, DeviceType.gateway, DeviceStatus.operational),
          ]),
        ).isEmpty,
        isTrue,
      );
    });
  });
}

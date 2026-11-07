// US20, US32, TS10: reglas del dominio de dispositivos.
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/parking_sensing.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

import '../../helpers/fake_clock.dart';
import 'support.dart';

NewDevice? _valid({
  DeviceType type = DeviceType.spaceSensor,
  String id = 'SENS-L1-01',
  int? interval = 60,
  bool? directional,
}) => NewDevice.create(
  lotId: const LotId(1),
  type: type,
  hardwareId: id,
  expectedReportIntervalSec: interval,
  directional: directional,
).valueOrNull;

Map<String, List<String>> _errors({
  DeviceType type = DeviceType.spaceSensor,
  String id = 'SENS-L1-01',
  int? interval = 60,
  bool? directional,
}) {
  final result = NewDevice.create(
    lotId: const LotId(1),
    type: type,
    hardwareId: id,
    expectedReportIntervalSec: interval,
    directional: directional,
  );
  final failure = result.failureOrNull;
  return failure is ValidationFailure ? failure.errors : const {};
}

void main() {
  group('NewDevice (US32 esc. 1)', () {
    test('un sensor de espacio válido; el identificador se recorta', () {
      final device = _valid(id: '  SENS-L1-01 ');

      expect(device?.hardwareId, 'SENS-L1-01');
      expect(device?.expectedReportInterval, const Duration(seconds: 60));
      expect(device?.directional, isNull);
      expect(device?.needsAssignment, isTrue);
    });

    test('un gateway válido no necesita asignación', () {
      final device = _valid(type: DeviceType.gateway);

      expect(device?.needsAssignment, isFalse);
    });

    test('el sensor de paso exige la direccionalidad (docs/06)', () {
      expect(_errors(type: DeviceType.passSensor), {
        'directional': ['required'],
      });
      expect(
        _valid(type: DeviceType.passSensor, directional: false)?.directional,
        isFalse,
      );
      expect(
        _valid(type: DeviceType.passSensor, directional: true)?.directional,
        isTrue,
      );
    });

    test('los demás tipos no admiten la direccionalidad', () {
      expect(_errors(directional: true), {
        'directional': ['not-allowed'],
      });
      expect(_errors(type: DeviceType.gateway, directional: false), {
        'directional': ['not-allowed'],
      });
    });

    test('identificador vacío o de más de 80 caracteres, e intervalo no '
        'positivo', () {
      expect(_errors(id: '   '), {
        'hardwareId': ['required'],
      });
      expect(_errors(id: 'x' * 81), {
        'hardwareId': ['too-long'],
      });
      expect(_valid(id: 'x' * 80), isNotNull);
      expect(_errors(interval: 0), {
        'expectedReportIntervalSec': ['positive'],
      });
      expect(_errors(interval: null), {
        'expectedReportIntervalSec': ['positive'],
      });
    });

    test('varios errores llegan juntos', () {
      expect(
        _errors(id: '', interval: -5, type: DeviceType.passSensor).keys,
        unorderedEquals([
          'hardwareId',
          'expectedReportIntervalSec',
          'directional',
        ]),
      );
    });
  });

  group('Device', () {
    test('pide atención solo sin comunicación o con batería baja', () {
      expect(device(1).needsAttention, isFalse);
      expect(
        device(1, status: DeviceStatus.unreachable).needsAttention,
        isTrue,
      );
      expect(device(1, status: DeviceStatus.lowBattery).needsAttention, isTrue);
      expect(
        device(1, status: DeviceStatus.decommissioned).needsAttention,
        isFalse,
      );
      expect(
        device(1, status: DeviceStatus.decommissioned).isDecommissioned,
        isTrue,
      );
    });
  });

  group('DeviceInventory', () {
    final devices = [
      device(1, spaceLabel: 'A-01'),
      device(2, status: DeviceStatus.lowBattery, spaceLabel: 'A-18'),
      device(3, status: DeviceStatus.unreachable, spaceLabel: 'B-19'),
      device(4, status: DeviceStatus.decommissioned, spaceLabel: 'C-22'),
      device(
        5,
        type: DeviceType.gateway,
        hardwareId: 'GW-L1-01',
        batteryPct: null,
      ),
    ];

    test('cuenta por estado y los que piden atención', () {
      final inv = inventory(devices);

      expect(inv.countOf(DeviceStatus.operational), 2);
      expect(inv.countOf(DeviceStatus.lowBattery), 1);
      expect(inv.countOf(DeviceStatus.decommissioned), 1);
      expect(inv.attentionCount, 2);
    });

    test('filtra por estado y busca por identificador o por espacio, sin '
        'distinguir mayúsculas', () {
      final inv = inventory(devices);

      expect(
        inv.where(status: DeviceStatus.lowBattery).map((d) => d.id.value),
        [2],
      );
      expect(inv.where(query: 'gw-l1').map((d) => d.id.value), [5]);
      expect(inv.where(query: ' b-19 ').map((d) => d.id.value), [3]);
      expect(inv.where(query: 'qs-l1-2').map((d) => d.id.value), [2]);
      expect(
        inv
            .where(status: DeviceStatus.operational, query: 'a-')
            .map(
              (d) => d.id.value,
            ),
        [1],
      );
      expect(inv.where(query: 'nada'), isEmpty);
      expect(inv.where(), hasLength(5));
    });

    test('la última comunicación usa la hora del servidor y el reloj '
        'monótono, no el del teléfono', () {
      final clock = FakeClock();
      final inv = inventory([device(1)], receivedAt: clock.monotonic());

      expect(inv.lastSeenAge(device(1), clock), const Duration(seconds: 20));

      // El reloj de pared desfasado no cambia nada.
      clock.wallClock = DateTime.utc(2030);
      expect(inv.lastSeenAge(device(1), clock), const Duration(seconds: 20));

      // El tiempo transcurrido localmente suma.
      clock.advance(const Duration(seconds: 40));
      expect(inv.lastSeenAge(device(1), clock), const Duration(seconds: 60));
    });

    test('un dispositivo que nunca reportó no tiene antigüedad', () {
      final clock = FakeClock();
      final never = device(1, seenAgo: null);

      expect(inventory([never]).lastSeenAge(never, clock), isNull);
    });
  });
}

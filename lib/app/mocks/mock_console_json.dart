import 'package:quadrapp_mobile/app/mocks/mock_world.dart';
import 'package:quadrapp_mobile/app/mocks/prediction_advisory/mock_prediction_json.dart';

String _iso(DateTime value) => value.toUtc().toIso8601String();

/// `GET /console/overview?lotId=` con el formato de docs/07 (TS17).
///
/// - La saturación sale del primer horizonte (15, 30, 45 o 60) que la prevé;
///   sin ninguno, `null` ("no se prevé saturación").
/// - Si la semilla marca una sección como no disponible (o el interruptor de
///   respuesta parcial está activo), llega `null` y se lista en `unavailable`:
///   la respuesta parcial de TS17 esc. 3.
Map<String, Object?> mockOverviewJson(MockWorld world, MockLot lot) {
  final now = world.clock.now();
  final age = now.difference(lot.consolidatedAt);
  final unavailable = <String>[
    ...lot.consoleUnavailable,
    if (world.controls.forceConsolePartial &&
        !lot.consoleUnavailable.contains('saturation'))
      'saturation',
  ];

  Object? saturation;
  if (!unavailable.contains('saturation')) {
    for (final horizon in const [15, 30, 45, 60]) {
      final forecast = mockForecastJson(world, lot, horizon);
      if (forecast['saturation'] != null) {
        saturation = forecast['saturation'];
        break;
      }
    }
  }

  final flow = lot.flow;
  return {
    'lotId': lot.id,
    'capacity': lot.capacity,
    'free': lot.count('FREE'),
    'occupied': lot.count('OCCUPIED'),
    'unknown': lot.count('UNKNOWN'),
    'flow': unavailable.contains('flow') || flow == null
        ? null
        : {
            'entries': flow.entries,
            'exits': flow.exits,
            'windowMin': flow.windowMin,
          },
    'saturation': saturation,
    'consolidatedAt': _iso(lot.consolidatedAt),
    'serverTime': _iso(now),
    'staleAfterSeconds': lot.staleAfterSeconds,
    'stale': age > Duration(seconds: lot.staleAfterSeconds),
    'unavailable': unavailable,
  };
}

/// Un dispositivo con el formato de docs/07 (cada elemento de `GET
/// /devices/health` y la respuesta de `POST /devices`).
Map<String, Object?> mockDeviceJson(
  MockWorld world,
  MockDevice device,
) {
  String? spaceLabel;
  if (device.spaceId != null) {
    final spaces = world.lot(device.lotId)?.spaces ?? const <MockSpace>[];
    for (final space in spaces) {
      if (space.id == device.spaceId) spaceLabel = space.label;
    }
  }
  return {
    'id': device.id,
    'hardwareId': device.hardwareId,
    'type': device.type,
    'status': device.status,
    'batteryPct': ?device.batteryPct,
    'lastSeenAt': ?(device.lastSeen == null ? null : _iso(device.lastSeen!)),
    'expectedReportIntervalSec': device.expectedReportIntervalSec,
    'directional': ?device.directional,
    'spaceLabel': ?spaceLabel,
  };
}

/// `GET /devices/health?lotId=` con el formato de docs/07 (TS10).
Map<String, Object?> mockDevicesHealthJson(MockWorld world, MockLot lot) => {
  'serverTime': _iso(world.clock.now()),
  'devices': [
    for (final device in world.devicesOf(lot.id)) mockDeviceJson(world, device),
  ],
};

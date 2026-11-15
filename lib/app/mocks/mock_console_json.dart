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

/// Reparte [total] en [buckets] minutos con un patrón fijo (siempre el mismo
/// para el mismo estacionamiento), sin perder ninguno: el resto va a los
/// minutos de mayor peso.
List<int> _spread(int total, int buckets, int salt) {
  if (buckets <= 0) return const [];
  final weights = [for (var i = 0; i < buckets; i++) 1 + (i * 7 + salt) % 5];
  final sum = weights.fold(0, (a, b) => a + b);
  final shares = [for (final w in weights) total * w ~/ sum];
  var left = total - shares.fold(0, (a, b) => a + b);
  final order = List<int>.generate(buckets, (i) => i)
    ..sort((a, b) => weights[b].compareTo(weights[a]));
  for (var i = 0; left > 0; i = (i + 1) % buckets, left--) {
    shares[order[i]]++;
  }
  return shares;
}

/// El estado de un acceso según sus sensores de paso: sin conteo, sin señal
/// (algún sensor no se comunica o ya no existe) u operativo.
String _accessStatus(MockWorld world, MockAccess access) {
  if (!access.flowCountingEnabled) return 'NOT_COUNTING';
  final devices = {for (final d in world.devices) d.id: d};
  for (final id in access.passSensorIds) {
    final status = devices[id]?.status;
    if (status == null ||
        status == 'UNREACHABLE' ||
        status == 'DECOMMISSIONED') {
      return 'UNREACHABLE';
    }
  }
  return 'OPERATIONAL';
}

/// `GET /console/accesses?lotId=` con el formato de docs/07 (US19, US29).
///
/// - El flujo es el del periodo de la semilla (`console.flow`), con la serie
///   por minuto repartida de forma fija y terminada en el minuto en curso;
///   `null` si ningún acceso cuenta flujo.
/// - Si la semilla marca `flow` como no disponible, llega `null` y se lista en
///   `unavailable`.
/// - Las entradas y salidas de cada acceso solo llegan si está operativo.
Map<String, Object?> mockAccessesJson(MockWorld world, MockLot lot) {
  final now = world.clock.now();
  final age = now.difference(lot.consolidatedAt);
  final unavailable = [
    if (lot.consoleUnavailable.contains('flow')) 'flow',
  ];
  final flow = lot.flow;

  Object? flowJson;
  if (flow != null && unavailable.isEmpty) {
    final window = flow.windowMin;
    final entries = _spread(flow.entries, window, lot.id * 3);
    final exits = _spread(flow.exits, window, lot.id * 3 + 2);
    final current = DateTime.utc(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute,
    );
    flowJson = {
      'entries': flow.entries,
      'exits': flow.exits,
      'windowMin': window,
      'series': [
        for (var i = 0; i < window; i++)
          {
            'minuteStart': _iso(
              current.subtract(Duration(minutes: window - 1 - i)),
            ),
            'entries': entries[i],
            'exits': exits[i],
          },
      ],
    };
  }

  return {
    'lotId': lot.id,
    'settings': {
      'opensAt': lot.opensAt,
      'closesAt': lot.closesAt,
      'saturationThresholdPct': lot.saturationThresholdPct,
    },
    'flow': flowJson,
    'accesses': [
      for (final access in lot.accesses)
        () {
          final status = _accessStatus(world, access);
          final counts = status == 'OPERATIONAL';
          return {
            'id': access.id,
            'name': access.name,
            'type': access.type,
            'flowCountingEnabled': access.flowCountingEnabled,
            'status': status,
            'entries': counts ? access.entries : null,
            'exits': counts ? access.exits : null,
          };
        }(),
    ],
    'consolidatedAt': _iso(lot.consolidatedAt),
    'serverTime': _iso(now),
    'staleAfterSeconds': lot.staleAfterSeconds,
    'stale': age > Duration(seconds: lot.staleAfterSeconds),
    'unavailable': unavailable,
  };
}

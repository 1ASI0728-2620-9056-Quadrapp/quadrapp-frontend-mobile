/// Un dispositivo del inventario en el mundo simulado (valores tal cual los
/// envía el backend: tipo `SPACE_SENSOR`, `PASS_SENSOR` o `GATEWAY`; estado
/// `OPERATIONAL`, `UNREACHABLE`, `LOW_BATTERY` o `DECOMMISSIONED`).
class MockDevice {
  MockDevice({
    required this.id,
    required this.lotId,
    required this.hardwareId,
    required this.type,
    required this.status,
    required this.expectedReportIntervalSec,
    this.batteryPct,
    this.lastSeen,
    this.directional,
    this.spaceId,
  });

  final int id;
  final int lotId;
  final String hardwareId;
  final String type;
  String status;
  final int expectedReportIntervalSec;
  final int? batteryPct;

  /// Cuándo reportó por última vez (UTC); `null` si nunca.
  final DateTime? lastSeen;

  /// Solo en `PASS_SENSOR`.
  final bool? directional;

  /// El espacio al que está asociado, si lo tiene (US18 es de la consola web).
  final int? spaceId;
}

/// El flujo de entradas y salidas del periodo de un estacionamiento (TS17).
class MockFlow {
  const MockFlow({
    required this.entries,
    required this.exits,
    required this.windowMin,
  });

  final int entries;
  final int exits;
  final int windowMin;
}

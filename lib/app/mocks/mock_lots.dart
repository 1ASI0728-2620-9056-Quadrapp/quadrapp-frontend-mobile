import 'package:quadrapp_mobile/app/mocks/mock_devices.dart';

/// Estado de un espacio en el mundo simulado (valores tal cual los envía el
/// backend: `FREE`, `OCCUPIED`, `UNKNOWN`).
class MockSpace {
  MockSpace({
    required this.id,
    required this.levelId,
    required this.label,
    required this.posX,
    required this.posY,
    required this.status,
    this.unknownReason,
  });

  final int id;
  final int levelId;
  final String label;
  final double posX;
  final double posY;
  String status;
  String? unknownReason;
}

/// Un sótano o un piso de una zona.
class MockLevel {
  MockLevel({required this.id, required this.name, required this.spaces});

  final int id;
  final String name;
  final List<MockSpace> spaces;
}

/// Un pabellón o un área de la sede, con sus niveles.
class MockZone {
  MockZone({
    required this.id,
    required this.name,
    required this.levels,
    this.description,
  });

  final int id;
  final String name;
  final String? description;
  final List<MockLevel> levels;

  /// Todos los espacios de la zona, de todos sus niveles.
  Iterable<MockSpace> get spaces => levels.expand((l) => l.spaces);
}

/// Próxima liberación de un estacionamiento lleno (US36), tal como la
/// publica la semilla.
class MockNextAvailability {
  const MockNextAvailability({
    required this.minMinutes,
    required this.maxMinutes,
    required this.confidence,
  });

  final int minMinutes;
  final int maxMinutes;
  final double confidence;
}

/// Lo que la semilla dice del pronóstico de un estacionamiento. La ocupación
/// esperada no está aquí: se deriva de la ocupación actual (docs/07).
class MockForecastSeed {
  const MockForecastSeed({
    required this.method,
    required this.confidenceByHorizon,
    this.saturationInMinutes,
    this.nextAvailability,
  });

  /// `PRIMARY_MODEL` o `FALLBACK`.
  final String method;

  /// Confianza (0 a 1) de cada horizonte: 15, 30, 45 y 60.
  final Map<int, double> confidenceByHorizon;

  /// Dentro de cuántos minutos se prevé la saturación, si se prevé.
  final int? saturationInMinutes;
  final MockNextAvailability? nextAvailability;

  bool get isFallback => method == 'FALLBACK';
}

class MockLot {
  MockLot({
    required this.id,
    required this.name,
    required this.layoutVersion,
    required this.zones,
    required this.consolidatedAt,
    required this.forecast,
    this.address,
    this.latitude,
    this.longitude,
    this.staleAfterSeconds = 180,
    this.saturationThresholdPct = 90,
    this.flow,
    this.consoleUnavailable = const [],
  });

  final int id;
  final String name;
  final String? address;

  /// Sin coordenadas solo hay ETA manual.
  final double? latitude;
  final double? longitude;

  /// 0 = sin distribución publicada (US04 esc. 2).
  final int layoutVersion;
  final List<MockZone> zones;
  final int staleAfterSeconds;

  /// `saturation_threshold_pct` de docs/06.
  final int saturationThresholdPct;
  final MockForecastSeed forecast;

  /// Flujo de entradas y salidas del periodo; `null` sin conteo habilitado.
  final MockFlow? flow;

  /// Secciones de `GET /console/overview` que no pudieron obtenerse
  /// (`saturation`, `flow`): la respuesta parcial de TS17 esc. 3.
  final List<String> consoleUnavailable;

  DateTime consolidatedAt;

  /// Sin historial suficiente: los pronósticos usan el método de respaldo con
  /// confianza baja (US09 esc. 3, US12).
  bool get insufficientHistory => forecast.isFallback;

  bool get hasLayout => layoutVersion > 0;

  Iterable<MockSpace> get spaces => zones.expand((z) => z.spaces);

  Iterable<MockLevel> get levels => zones.expand((z) => z.levels);

  int count(String status) => spaces.where((s) => s.status == status).length;

  int get capacity => spaces.length;

  /// ¿Los ocupados alcanzan el umbral de saturación del estacionamiento?
  /// Los desconocidos quedan fuera del cálculo.
  bool get isSaturated {
    final counted = count('FREE') + count('OCCUPIED');
    return counted > 0 &&
        count('OCCUPIED') * 100 >= saturationThresholdPct * counted;
  }
}

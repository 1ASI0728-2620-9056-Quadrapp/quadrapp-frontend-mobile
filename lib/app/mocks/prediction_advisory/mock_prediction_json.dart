import 'dart:math';

import 'package:quadrapp_mobile/app/mocks/mock_world.dart';

/// Reglas de los mocks de predicción (docs/07, "Datos y comportamiento de los
/// mocks"). Todo sale de [MockWorld], así los pronósticos son coherentes con
/// la ocupación que muestra el contexto `occupancy`.
abstract final class MockPredictionRules {
  /// Cuánto dura un pronóstico desde su generación.
  static const Duration forecastValidity = Duration(minutes: 15);

  /// Hace cuánto se "generó" el pronóstico respecto de la hora del servidor.
  static const Duration forecastAge = Duration(minutes: 2);

  /// A partir de esta ocupación esperada (%) se prevé saturación.
  static const double saturationThresholdPct = 90;

  /// Crecimiento esperado de la ocupación por minuto de horizonte, en puntos
  /// porcentuales, para un estacionamiento con historial suficiente.
  static const double growthPctPerMinute = 0.49;

  /// Ocupación base (%) de un estacionamiento sin distribución publicada: no
  /// hay espacios que contar, así que el respaldo usa un valor fijo.
  static const double noLayoutBasePct = 55;

  /// Confianza fija del método de respaldo (siempre `LOW`).
  static const double fallbackConfidence = 0.2;

  /// Espacios libres esperados con los que la probabilidad llega a 1.
  static const double spacesForCertainty = 36;

  static const int maxEtaMinutes = 120;
}

String _iso(DateTime value) => value.toUtc().toIso8601String();

/// `LOW` / `MEDIUM` / `HIGH` según el valor (>= 0.7, >= 0.4, resto).
String mockConfidenceLevel(double value) {
  if (value >= 0.7) return 'HIGH';
  if (value >= 0.4) return 'MEDIUM';
  return 'LOW';
}

Map<String, Object?> mockConfidenceJson(double value) => {
  'value': double.parse(value.toStringAsFixed(2)),
  'level': mockConfidenceLevel(value),
};

/// Ocupación esperada (%) de [lot] dentro de [horizon] minutos.
double mockExpectedOccupancyPct(MockLot lot, int horizon) {
  if (lot.insufficientHistory && !lot.hasLayout) {
    return MockPredictionRules.noLayoutBasePct;
  }
  final current = lot.capacity == 0
      ? MockPredictionRules.noLayoutBasePct
      : lot.count('OCCUPIED') / lot.capacity * 100;
  final growth = lot.insufficientHistory
      ? 0
      : MockPredictionRules.growthPctPerMinute * horizon;
  return min(100, current + growth).toDouble();
}

/// La confianza del horizonte, tal como la publica la semilla.
double _confidenceValue(MockLot lot, int horizon) =>
    lot.forecast.confidenceByHorizon[horizon] ??
    MockPredictionRules.fallbackConfidence;

/// `GET /forecasts` con el formato de docs/07.
Map<String, Object?> mockForecastJson(
  MockWorld world,
  MockLot lot,
  int horizon,
) {
  final now = world.clock.now();
  final generatedAt = now.subtract(MockPredictionRules.forecastAge);
  final expected = mockExpectedOccupancyPct(lot, horizon);
  final saturates = expected >= MockPredictionRules.saturationThresholdPct;
  return {
    'horizon': horizon,
    'expectedOccupancyPct': double.parse(expected.toStringAsFixed(1)),
    'confidence': mockConfidenceJson(_confidenceValue(lot, horizon)),
    'modelVersion': lot.insufficientHistory ? 'baseline-2026.09' : 'm-2026.09',
    'method': lot.insufficientHistory ? 'FALLBACK' : 'PRIMARY_MODEL',
    'generatedAt': _iso(generatedAt),
    'validUntil': _iso(generatedAt.add(MockPredictionRules.forecastValidity)),
    'serverTime': _iso(now),
    if (saturates)
      'saturation': {
        'expectedAt': _iso(
          now.add(
            Duration(
              minutes: lot.forecast.saturationInMinutes ?? (horizon / 3).ceil(),
            ),
          ),
        ),
        'pct': double.parse(min(100, expected).toStringAsFixed(1)),
      },
  };
}

/// `POST /arrival-advices` con el formato de docs/07.
Map<String, Object?> mockAdviceJson(
  MockWorld world,
  MockLot lot,
  int etaMinutes,
) {
  final now = world.clock.now();
  final horizonUsed = _nearestHorizon(etaMinutes);
  final expected = mockExpectedOccupancyPct(lot, horizonUsed);
  final double probability;
  if (lot.capacity == 0) {
    probability = (100 - expected) / 100;
  } else {
    final freeExpected =
        lot.capacity * (1 - expected / 100) - lot.count('UNKNOWN');
    probability = (freeExpected / MockPredictionRules.spacesForCertainty).clamp(
      0.0,
      1.0,
    );
  }
  final category = probability >= 0.7
      ? 'HIGH'
      : probability >= 0.3
      ? 'LIMITED'
      : 'LOW';
  return {
    'etaMinutes': etaMinutes,
    'probabilityOfSpace': double.parse(probability.toStringAsFixed(2)),
    'category': category,
    'confidence': mockConfidenceJson(_confidenceValue(lot, horizonUsed)),
    'horizonUsed': horizonUsed,
    'generatedAt': _iso(now.subtract(MockPredictionRules.forecastAge)),
    'serverTime': _iso(now),
  };
}

/// `GET /forecasts/{lotId}/next-availability` con el formato de docs/07.
Map<String, Object?> mockNextAvailabilityJson(MockWorld world, MockLot lot) {
  final serverTime = _iso(world.clock.now());
  if (lot.count('FREE') > 0) {
    return {
      'available': false,
      'reason': 'HAS_FREE_SPACES',
      'serverTime': serverTime,
    };
  }
  final next = lot.forecast.nextAvailability;
  if (world.controls.nextAvailabilityNoExits || next == null) {
    return {'available': false, 'reason': 'NO_EXITS', 'serverTime': serverTime};
  }
  return {
    'available': true,
    'minMinutes': next.minMinutes,
    'maxMinutes': next.maxMinutes,
    'confidence': mockConfidenceJson(next.confidence),
    'serverTime': serverTime,
  };
}

/// El horizonte más cercano al ETA (empate: el mayor; más de 60: 60). Es la
/// misma regla que `ForecastHorizon.nearestTo`, repetida aquí a propósito: el
/// mock hace de servidor y no puede importar el dominio de la app.
int _nearestHorizon(int etaMinutes) {
  const horizons = [15, 30, 45, 60];
  var best = horizons.first;
  for (final horizon in horizons) {
    final distance = (horizon - etaMinutes).abs();
    final bestDistance = (best - etaMinutes).abs();
    if (distance < bestDistance ||
        (distance == bestDistance && horizon > best)) {
      best = horizon;
    }
  }
  return best;
}

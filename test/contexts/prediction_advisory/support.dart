import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/entities/arrival_advice.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/entities/forecast.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/arrival_category.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/confidence.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/eta_minutes.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/forecast_horizon.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/forecast_validity.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

import '../../helpers/fake_clock.dart';

/// La hora del servidor de `FakeClock` por defecto.
final serverTime = DateTime.utc(2026, 9, 28, 13, 42);

const lotId = LotId(1);

EtaMinutes eta(int minutes) =>
    EtaMinutes.create(minutes).valueOrNull ?? (throw StateError('ETA'));

/// Pronóstico de muestra, vigente 13 minutos desde `FakeClock()`.
Forecast sampleForecast({
  ForecastHorizon horizon = ForecastHorizon.min30,
  ForecastMethod method = ForecastMethod.primaryModel,
  ConfidenceLevel level = ConfidenceLevel.high,
  Duration validFor = const Duration(minutes: 13),
}) => Forecast(
  horizon: horizon,
  expectedOccupancyPct: 86,
  confidence: Confidence(value: 0.71, level: level),
  modelVersion: 'm-2026.09',
  method: method,
  generatedAt: DateTime.utc(2026, 9, 28, 13, 40),
  validity: ForecastValidity(
    validUntil: serverTime.add(validFor),
    serverTime: serverTime,
    receivedAt: FakeClock().monotonic(),
  ),
);

ArrivalAdvice sampleAdvice({
  int etaMinutes = 20,
  ArrivalCategory? category = ArrivalCategory.high,
}) => ArrivalAdvice(
  etaMinutes: eta(etaMinutes),
  probabilityOfSpace: 0.82,
  category: category,
  confidence: const Confidence(value: 0.64, level: ConfidenceLevel.medium),
  horizonUsed: ForecastHorizon.min15,
  generatedAt: DateTime.utc(2026, 9, 28, 13, 40),
);

Map<String, Object?> confidenceJson({
  double value = 0.71,
  String level = 'HIGH',
}) => {'value': value, 'level': level};

/// `GET /forecasts` con el formato de docs/07.
Map<String, Object?> forecastJson({
  int horizon = 30,
  String method = 'PRIMARY_MODEL',
  String level = 'HIGH',
  Object? saturation = const {
    'expectedAt': '2026-09-28T14:10:00Z',
    'pct': 93.5,
  },
}) => {
  'horizon': horizon,
  'expectedOccupancyPct': 86.0,
  'confidence': confidenceJson(level: level),
  'modelVersion': 'm-2026.09',
  'method': method,
  'generatedAt': '2026-09-28T13:40:00Z',
  'validUntil': '2026-09-28T13:55:00Z',
  'serverTime': '2026-09-28T13:42:00Z',
  'saturation': saturation,
};

/// `POST /arrival-advices` con el formato de docs/07.
Map<String, Object?> adviceJson({
  String category = 'HIGH',
  String level = 'MEDIUM',
  int etaMinutes = 20,
}) => {
  'etaMinutes': etaMinutes,
  'probabilityOfSpace': 0.82,
  'category': category,
  'confidence': confidenceJson(value: 0.64, level: level),
  'horizonUsed': 15,
  'generatedAt': '2026-09-28T13:40:00Z',
  'serverTime': '2026-09-28T13:42:00Z',
};

/// `GET /forecasts/{lotId}/next-availability` con el formato de docs/07.
Map<String, Object?> nextAvailabilityJson({
  bool available = true,
  String? reason,
  int? minMinutes = 8,
  int? maxMinutes = 15,
}) => {
  'available': available,
  'reason': ?reason,
  if (available) ...{
    'minMinutes': minMinutes,
    'maxMinutes': maxMinutes,
    'confidence': confidenceJson(value: 0.55, level: 'MEDIUM'),
  },
  'serverTime': '2026-09-28T13:42:00Z',
};

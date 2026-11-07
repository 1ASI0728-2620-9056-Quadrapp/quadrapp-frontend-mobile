import 'package:quadrapp_mobile/composition/arrival/arrival_state.dart';
import 'package:quadrapp_mobile/composition/forecast/forecast_state.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/prediction_advisory.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

/// Momento de referencia de las pruebas (UTC); coincide con la hora del
/// `FakeClock` por defecto.
final DateTime t0 = DateTime.utc(2026, 9, 28, 13, 42);

ParkingLot lot({int id = 1, int layoutVersion = 4}) => ParkingLot(
  id: LotId(id),
  name: 'Sede $id',
  layoutVersion: layoutVersion,
  staleAfter: const Duration(seconds: 180),
);

/// Un pronóstico generado hace 2 min, vigente [validFor] más y con la
/// confianza [confidence].
Forecast forecast(
  ForecastHorizon horizon, {
  double expected = 72,
  double confidence = 0.8,
  ConfidenceLevel level = ConfidenceLevel.high,
  ForecastMethod method = ForecastMethod.primaryModel,
  Duration validFor = const Duration(minutes: 13),
  Saturation? saturation,
}) => Forecast(
  horizon: horizon,
  expectedOccupancyPct: expected,
  confidence: Confidence(value: confidence, level: level),
  modelVersion: method == ForecastMethod.fallback
      ? 'baseline-2026.09'
      : 'm-2026.09',
  method: method,
  generatedAt: t0.subtract(const Duration(minutes: 2)),
  validity: ForecastValidity(
    validUntil: t0.add(validFor),
    serverTime: t0,
    receivedAt: Duration.zero,
  ),
  saturation: saturation,
);

/// Los cuatro horizontes con los pronósticos [overrides]; los demás, con los
/// valores por defecto.
LotForecasts forecasts({
  Map<ForecastHorizon, Forecast> overrides = const {},
  Set<ForecastHorizon> missing = const {},
}) => LotForecasts([
  for (final horizon in ForecastHorizon.values)
    if (!missing.contains(horizon)) overrides[horizon] ?? forecast(horizon),
]);

ArrivalAdvice advice(
  ForecastHorizon horizon, {
  double probability = 0.82,
  ArrivalCategory? category = ArrivalCategory.high,
  ConfidenceLevel level = ConfidenceLevel.high,
}) => ArrivalAdvice(
  etaMinutes: EtaMinutes.create(horizon.minutes).valueOrNull!,
  probabilityOfSpace: probability,
  category: category,
  confidence: Confidence(value: 0.8, level: level),
  generatedAt: t0.subtract(const Duration(minutes: 2)),
  serverTime: t0,
  receivedAt: Duration.zero,
);

/// La asesoría de cada horizonte: 88, 82, 61 y 38 % (buena, buena, limitada y
/// baja), como en el diseño.
List<HorizonAdvice> advices({Set<ForecastHorizon> missing = const {}}) {
  const odds = {
    ForecastHorizon.min15: (0.88, ArrivalCategory.high),
    ForecastHorizon.min30: (0.82, ArrivalCategory.high),
    ForecastHorizon.min45: (0.61, ArrivalCategory.limited),
    ForecastHorizon.min60: (0.38, ArrivalCategory.low),
  };
  return [
    for (final horizon in ForecastHorizon.values)
      HorizonAdvice(
        horizon,
        missing.contains(horizon)
            ? null
            : advice(
                horizon,
                probability: odds[horizon]!.$1,
                category: odds[horizon]!.$2,
              ),
      ),
  ];
}

ForecastOverview overview({
  ParkingLot? parkingLot,
  LotForecasts? lotForecasts,
  List<HorizonAdvice>? lotAdvices,
  bool withForecasts = true,
}) => ForecastOverview(
  lot: parkingLot ?? lot(),
  forecasts: withForecasts ? (lotForecasts ?? forecasts()) : null,
  advices: lotAdvices ?? advices(),
);

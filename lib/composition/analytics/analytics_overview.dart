// US21, US22, US34
import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/analytics/analytics.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/prediction_advisory.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';

/// Las partes de Analítica que se piden por separado: una puede faltar sin
/// tumbar las demás (respuesta parcial).
enum AnalyticsSection { occupancy, peaks, accuracy, forecast }

/// El tramo de la próxima hora en que el pronóstico supera el umbral de
/// ocupación del estacionamiento, con su confianza y su hora de generación
/// (toda predicción las muestra).
class AnalyticsRisk extends Equatable {
  const AnalyticsRisk({
    required this.from,
    required this.to,
    required this.peakPct,
    required this.confidence,
    required this.generatedAt,
  });

  /// Primer y último momento previsto sobre el umbral (UTC).
  final DateTime from;
  final DateTime to;

  /// La mayor ocupación prevista del tramo (0 a 100).
  final double peakPct;

  /// La confianza del primer pronóstico sobre el umbral.
  final Confidence confidence;
  final DateTime generatedAt;

  @override
  List<Object?> get props => [from, to, peakPct, confidence, generatedAt];
}

/// Lo que muestra Analítica y precisión (`/ops/analytics`) para un
/// estacionamiento, un periodo y, si se filtra, una zona.
class AnalyticsOverview extends Equatable {
  const AnalyticsOverview({
    required this.lotId,
    required this.period,
    required this.range,
    this.zoneId,
    this.history,
    this.peaks,
    this.accuracy,
    this.forecasts,
    this.failures = const {},
  });

  final LotId lotId;
  final AnalyticsPeriod period;
  final AnalyticsRange range;

  /// `null`: todo el estacionamiento (US21 esc. 2).
  final ZoneId? zoneId;

  final OccupancyHistory? history;
  final PeakHours? peaks;
  final ForecastAccuracy? accuracy;

  /// El pronóstico del estacionamiento para la próxima hora. Solo se pide en
  /// «Hoy» y sin filtro de zona: el pronóstico es por estacionamiento.
  final LotForecasts? forecasts;

  /// Las partes que no llegaron y por qué.
  final Map<AnalyticsSection, Failure> failures;

  /// ¿La gráfica lleva el pronóstico? (hoy, todo el estacionamiento).
  bool get showsForecast => period == AnalyticsPeriod.today && zoneId == null;

  Set<String> get missing => {
    for (final section in failures.keys) section.name,
  };

  bool get isPartial => failures.isNotEmpty;

  /// Los pronósticos vigentes, del más cercano al más lejano.
  List<Forecast> currentForecasts(Clock clock) {
    final forecasts = this.forecasts;
    if (forecasts == null || !showsForecast) return const [];
    return [
      for (final slot in forecasts.slots(clock)) ?slot.current,
    ]..sort((a, b) => a.targetAt.compareTo(b.targetAt));
  }

  /// El tramo en que el pronóstico llega a [thresholdPct], o `null` si no se
  /// prevé.
  AnalyticsRisk? risk({required int thresholdPct, required Clock clock}) {
    final over = [
      for (final forecast in currentForecasts(clock))
        if (forecast.expectedOccupancyPct >= thresholdPct) forecast,
    ];
    if (over.isEmpty) return null;
    final first = over.first;
    return AnalyticsRisk(
      from: first.targetAt,
      to: over.last.targetAt,
      peakPct: over
          .map((f) => f.expectedOccupancyPct)
          .reduce((a, b) => a > b ? a : b),
      confidence: first.confidence,
      generatedAt: first.generatedAt,
    );
  }

  AnalyticsOverview copyWith({
    OccupancyHistory? history,
    Map<AnalyticsSection, Failure>? failures,
    ZoneId? zoneId,
    bool clearZone = false,
  }) {
    return AnalyticsOverview(
      lotId: lotId,
      period: period,
      range: range,
      zoneId: clearZone ? null : zoneId ?? this.zoneId,
      history: history ?? this.history,
      peaks: peaks,
      accuracy: accuracy,
      forecasts: forecasts,
      failures: failures ?? this.failures,
    );
  }

  @override
  List<Object?> get props => [
    lotId.value,
    period,
    range,
    zoneId?.value,
    history,
    peaks,
    accuracy,
    forecasts,
    failures,
  ];
}

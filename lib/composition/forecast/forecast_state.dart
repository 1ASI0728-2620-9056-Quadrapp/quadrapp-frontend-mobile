// US09, US10, US11, US12, US15
import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/composition/arrival/arrival_state.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/prediction_advisory.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';

/// Qué se sabe de un horizonte en la pantalla de Predicción (US10).
enum ForecastRowStatus {
  /// Hay un pronóstico vigente (o, sin el detalle, solo la asesoría).
  available,

  /// No hay pronóstico para este horizonte (esc. 2).
  missing,

  /// El pronóstico venció: no se muestra como actual (esc. 3).
  expired,
}

/// Un horizonte con lo que se sabe de él: su pronóstico (ocupación esperada,
/// confianza, origen) y la asesoría de llegada a esa hora (probabilidad y
/// categoría).
class ForecastRow extends Equatable {
  const ForecastRow({
    required this.horizon,
    required this.status,
    this.forecast,
    this.advice,
  });

  final ForecastHorizon horizon;
  final ForecastRowStatus status;

  /// El pronóstico; también cuando venció (para el detalle), pero entonces no
  /// se presenta como actual.
  final Forecast? forecast;

  /// La asesoría de llegada a esta hora (con categoría), si llegó.
  final ArrivalAdvice? advice;

  bool get isCurrent => status == ForecastRowStatus.available;

  /// La probabilidad de encontrar espacio y su categoría, solo si son
  /// actuales.
  ArrivalAdvice? get currentAdvice =>
      isCurrent && (advice?.isAvailable ?? false) ? advice : null;

  /// La confianza que se informa: la del pronóstico y, sin él, la de la
  /// asesoría. Nunca se traduce a una categoría de llegada (US11 esc. 3).
  Confidence? get confidence =>
      isCurrent ? (forecast?.confidence ?? advice?.confidence) : null;

  /// El pronóstico vigente sale de la estimación de contingencia por falta de
  /// historial (US12 esc. 1).
  bool get isFallback => isCurrent && (forecast?.isFallback ?? false);

  /// Se basa en información limitada: contingencia o confianza baja (US12).
  bool get isLowConfidence =>
      isCurrent &&
      ((forecast?.isLowConfidence ?? false) ||
          (advice?.isLowConfidence ?? false));

  /// Cuándo se generó (UTC).
  DateTime? get generatedAt => forecast?.generatedAt ?? advice?.generatedAt;

  /// Hace cuánto se generó: con la hora del servidor más el tiempo
  /// transcurrido localmente, nunca con el reloj del teléfono.
  Duration? age(Clock clock) => forecast?.age(clock) ?? advice?.age(clock);

  /// Momento al que se refiere (UTC): lo generado más el horizonte.
  DateTime? get targetAt =>
      forecast?.targetAt ??
      advice?.generatedAt.add(Duration(minutes: horizon.minutes));

  @override
  List<Object?> get props => [horizon, status, forecast, advice];
}

/// Lo que muestra Predicción de la sede elegida: los pronósticos y la asesoría
/// de cada horizonte. Es estado de presentación: combina datos de la misma
/// sede y no es una entidad del dominio.
class ForecastOverview extends Equatable {
  const ForecastOverview({
    required this.lot,
    this.forecasts,
    this.advices = const [],
    this.forecastsFailure,
  });

  final ParkingLot lot;

  /// Los pronósticos que existen; `null` si no se pudieron leer.
  final LotForecasts? forecasts;
  final List<HorizonAdvice> advices;
  final Failure? forecastsFailure;

  /// La sede sin distribución publicada se presenta sin información
  /// (US04 esc. 2).
  bool get hasNoData => !lot.hasPublishedLayout;

  /// Ningún horizonte tiene pronóstico ni asesoría (US10 esc. 2, todos).
  bool get hasNothing =>
      (forecasts?.isEmpty ?? true) && advices.every((a) => !a.isAvailable);

  /// Los cuatro horizontes (15, 30, 45 y 60), cada uno disponible, faltante o
  /// vencido según el reloj dado (la hora del servidor más el tiempo local).
  /// Sin el detalle de los pronósticos, cada horizonte se arma con su
  /// asesoría.
  List<ForecastRow> rows(Clock clock) {
    ArrivalAdvice? adviceOf(ForecastHorizon horizon) {
      for (final item in advices) {
        if (item.horizon == horizon && item.isAvailable) return item.advice;
      }
      return null;
    }

    final loaded = forecasts;
    if (loaded == null) {
      return [
        for (final horizon in ForecastHorizon.values)
          ForecastRow(
            horizon: horizon,
            status: adviceOf(horizon) == null
                ? ForecastRowStatus.missing
                : ForecastRowStatus.available,
            advice: adviceOf(horizon),
          ),
      ];
    }
    return [
      for (final slot in loaded.slots(clock))
        ForecastRow(
          horizon: slot.horizon,
          status: switch (slot.status) {
            ForecastSlotStatus.available => ForecastRowStatus.available,
            ForecastSlotStatus.missing => ForecastRowStatus.missing,
            ForecastSlotStatus.expired => ForecastRowStatus.expired,
          },
          forecast: slot.forecast,
          advice: adviceOf(slot.horizon),
        ),
    ];
  }

  @override
  List<Object?> get props => [lot, forecasts, advices, forecastsFailure];
}

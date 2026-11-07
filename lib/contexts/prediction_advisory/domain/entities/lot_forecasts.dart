import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/entities/forecast.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/forecast_horizon.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';

/// Estado de un horizonte en la pantalla de pronóstico (US10).
enum ForecastSlotStatus {
  /// Pronóstico vigente.
  available,

  /// No hay pronóstico para este horizonte (información parcial, esc. 2).
  missing,

  /// El pronóstico venció: no se muestra como actual (esc. 3).
  expired,
}

/// Un horizonte con su pronóstico (si lo hay) y su estado.
class ForecastSlot extends Equatable {
  const ForecastSlot({
    required this.horizon,
    required this.status,
    this.forecast,
  });

  final ForecastHorizon horizon;
  final ForecastSlotStatus status;

  /// El pronóstico. Está presente si `available` y también si `expired`
  /// (para poder indicar que venció), pero **no** debe mostrarse como actual
  /// cuando está vencido.
  final Forecast? forecast;

  /// Solo un pronóstico vigente se presenta como el actual.
  Forecast? get current =>
      status == ForecastSlotStatus.available ? forecast : null;

  @override
  List<Object?> get props => [horizon, status, forecast];
}

/// Los pronósticos que existen de un estacionamiento. Los horizontes faltantes
/// no están en [forecasts]; [slots] siempre da los cuatro horizontes.
class LotForecasts extends Equatable {
  const LotForecasts(this.forecasts);

  final List<Forecast> forecasts;

  /// Los cuatro horizontes (15, 30, 45 y 60), cada uno disponible, faltante o
  /// vencido según el reloj dado (la hora del servidor más el tiempo local).
  List<ForecastSlot> slots(Clock clock) {
    return [
      for (final horizon in ForecastHorizon.values) _slot(horizon, clock),
    ];
  }

  ForecastSlot _slot(ForecastHorizon horizon, Clock clock) {
    final forecast = forecasts.where((f) => f.horizon == horizon).firstOrNull;
    if (forecast == null) {
      return ForecastSlot(horizon: horizon, status: ForecastSlotStatus.missing);
    }
    return ForecastSlot(
      horizon: horizon,
      forecast: forecast,
      status: forecast.validity.isExpired(clock)
          ? ForecastSlotStatus.expired
          : ForecastSlotStatus.available,
    );
  }

  /// ¿Falta o venció algún horizonte? (información parcial).
  bool isPartial(Clock clock) =>
      slots(clock).any((s) => s.status != ForecastSlotStatus.available);

  /// Todos los horizontes faltan: la pantalla muestra un estado vacío.
  bool get isEmpty => forecasts.isEmpty;

  @override
  List<Object?> get props => [forecasts];
}

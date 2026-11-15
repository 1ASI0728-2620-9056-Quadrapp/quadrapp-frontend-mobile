import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/confidence.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/forecast_horizon.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/forecast_validity.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/saturation.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';

/// Cómo se generó el pronóstico.
enum ForecastMethod {
  /// Modelo principal (historial suficiente).
  primaryModel,

  /// Estimación de contingencia por historial insuficiente (US09 esc. 3, US12).
  fallback,
}

/// Pronóstico de ocupación de un estacionamiento a un horizonte (US09, US11).
class Forecast extends Equatable {
  const Forecast({
    required this.horizon,
    required this.expectedOccupancyPct,
    required this.confidence,
    required this.modelVersion,
    required this.method,
    required this.generatedAt,
    required this.validity,
    this.saturation,
  });

  final ForecastHorizon horizon;

  /// De 0 a 100 (puntos porcentuales).
  final double expectedOccupancyPct;
  final Confidence confidence;
  final String modelVersion;
  final ForecastMethod method;

  /// Cuándo se generó (UTC): se muestra junto a la confianza.
  final DateTime generatedAt;
  final ForecastValidity validity;

  /// Saturación prevista; `null` si no se prevé.
  final Saturation? saturation;

  /// Hace cuánto se generó: `serverTime − generatedAt` más el tiempo
  /// transcurrido localmente (reloj monótono), nunca la hora del teléfono.
  Duration age(Clock clock) {
    final atServer = validity.serverTime.difference(generatedAt);
    final local = clock.monotonic() - validity.receivedAt;
    return _nonNegative(atServer) + _nonNegative(local);
  }

  static Duration _nonNegative(Duration value) =>
      value.isNegative ? Duration.zero : value;

  /// Momento al que se refiere el pronóstico.
  DateTime get targetAt => generatedAt.add(Duration(minutes: horizon.minutes));

  bool get isFallback => method == ForecastMethod.fallback;

  /// Se basa en información limitada: contingencia o confianza baja. Se
  /// muestra con una advertencia (US12).
  bool get isLowConfidence => isFallback || confidence.isLow;

  @override
  List<Object?> get props => [
    horizon,
    expectedOccupancyPct,
    confidence,
    modelVersion,
    method,
    generatedAt,
    validity,
    saturation,
  ];
}

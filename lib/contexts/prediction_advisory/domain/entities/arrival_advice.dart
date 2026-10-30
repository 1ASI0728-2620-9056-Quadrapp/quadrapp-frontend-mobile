import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/arrival_category.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/confidence.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/eta_minutes.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/forecast_horizon.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';

/// Asesoría de llegada: la probabilidad de encontrar espacio a la hora
/// estimada de llegada y su categoría (US13 a US15).
class ArrivalAdvice extends Equatable {
  const ArrivalAdvice({
    required this.etaMinutes,
    required this.probabilityOfSpace,
    required this.confidence,
    required this.generatedAt,
    this.category,
    this.horizonUsed,
    this.serverTime,
    this.receivedAt,
  });

  /// El ETA para el que se generó.
  final EtaMinutes etaMinutes;

  /// De 0 a 1.
  final double probabilityOfSpace;

  /// `null` si el servidor envió una categoría que la app no reconoce: la
  /// asesoría se trata como no disponible y no se muestra ninguna categoría.
  final ArrivalCategory? category;
  final Confidence confidence;

  /// El horizonte de pronóstico usado (si es uno de los admitidos).
  final ForecastHorizon? horizonUsed;

  /// Cuándo se generó (UTC).
  final DateTime generatedAt;

  /// Hora del servidor al armar la respuesta (UTC) y lectura del reloj
  /// monótono cuando llegó: con ellas se calcula la antigüedad sin usar el
  /// reloj del teléfono.
  final DateTime? serverTime;
  final Duration? receivedAt;

  /// Hace cuánto se generó la predicción: `serverTime − generatedAt` más el
  /// tiempo transcurrido localmente (reloj monótono), nunca la hora del
  /// teléfono. Sin esos datos, cero.
  Duration age(Clock clock) {
    final server = serverTime;
    final received = receivedAt;
    if (server == null || received == null) return Duration.zero;
    final atServer = server.difference(generatedAt);
    final local = clock.monotonic() - received;
    return _nonNegative(atServer) + _nonNegative(local);
  }

  static Duration _nonNegative(Duration value) =>
      value.isNegative ? Duration.zero : value;

  /// ¿Se puede mostrar la categoría? Sin ella, la asesoría es no disponible.
  bool get isAvailable => category != null;

  /// Se basa en un pronóstico de contingencia o de confianza baja (US13
  /// esc. 3, US14 esc. 3): se muestra con una advertencia.
  bool get isLowConfidence => confidence.isLow;

  @override
  List<Object?> get props => [
    etaMinutes,
    probabilityOfSpace,
    category,
    confidence,
    horizonUsed,
    generatedAt,
    serverTime,
    receivedAt,
  ];
}

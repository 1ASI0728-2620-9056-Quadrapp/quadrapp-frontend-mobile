import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';

/// Vigencia de un pronóstico (US10 esc. 3). Como la antigüedad de la
/// ocupación, se calcula con la hora del **servidor** y no con la del
/// teléfono: `restante = validUntil − serverTime − tiempo transcurrido local`.
class ForecastValidity extends Equatable {
  const ForecastValidity({
    required this.validUntil,
    required this.serverTime,
    required this.receivedAt,
  });

  /// Hasta cuándo es vigente (UTC).
  final DateTime validUntil;

  /// Hora del servidor al armar la respuesta (UTC).
  final DateTime serverTime;

  /// Lectura del reloj monótono cuando llegó la respuesta.
  final Duration receivedAt;

  /// Cuánto queda de vigencia; negativo si ya venció.
  Duration remaining(Clock clock) {
    final local = clock.monotonic() - receivedAt;
    return validUntil.difference(serverTime) -
        (local.isNegative ? Duration.zero : local);
  }

  bool isExpired(Clock clock) => remaining(clock) <= Duration.zero;

  @override
  List<Object?> get props => [validUntil, serverTime, receivedAt];
}

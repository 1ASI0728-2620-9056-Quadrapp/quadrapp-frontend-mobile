import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';

/// Antigüedad de un dato de ocupación (US05 esc. 4, TS09 esc. 3).
///
/// Se calcula con la hora del **servidor**, no con la del teléfono:
/// `antigüedad = serverTime − consolidatedAt + tiempo transcurrido localmente`
/// desde que se recibió la respuesta. Así un reloj desfasado no altera el
/// resultado.
class Freshness extends Equatable {
  const Freshness({
    required this.consolidatedAt,
    required this.serverTime,
    required this.staleAfter,
    this.receivedAt,
    this.storedAt,
  });

  /// Momento al que corresponde el último dato consolidado (UTC).
  final DateTime consolidatedAt;

  /// Hora del servidor al armar la respuesta (UTC).
  final DateTime serverTime;

  /// Umbral a partir del cual el dato se considera desactualizado.
  final Duration staleAfter;

  /// Lectura del reloj monótono cuando llegó la respuesta (misma ejecución de
  /// la app). Es `null` si el dato salió de la caché.
  final Duration? receivedAt;

  /// Hora local (UTC) en que se guardó en caché. Solo para datos de caché,
  /// donde el reloj monótono ya no sirve tras reiniciar la app.
  final DateTime? storedAt;

  /// Cuánto tiempo pasó desde [consolidatedAt], según el servidor y el tiempo
  /// transcurrido localmente.
  Duration age(Clock clock) {
    final atServer = _nonNegative(serverTime.difference(consolidatedAt));
    final Duration local;
    if (receivedAt != null) {
      local = _nonNegative(clock.monotonic() - receivedAt!);
    } else if (storedAt != null) {
      local = _nonNegative(clock.now().difference(storedAt!));
    } else {
      local = Duration.zero;
    }
    return atServer + local;
  }

  /// ¿Superó el umbral de vigencia?
  bool isStale(Clock clock) => age(clock) > staleAfter;

  /// La misma antigüedad, ahora anclada a la hora local de guardado en caché.
  Freshness asCached(DateTime storedAt) => Freshness(
    consolidatedAt: consolidatedAt,
    serverTime: serverTime,
    staleAfter: staleAfter,
    storedAt: storedAt,
  );

  static Duration _nonNegative(Duration value) =>
      value.isNegative ? Duration.zero : value;

  @override
  List<Object?> get props => [
    consolidatedAt,
    serverTime,
    staleAfter,
    receivedAt,
    storedAt,
  ];
}

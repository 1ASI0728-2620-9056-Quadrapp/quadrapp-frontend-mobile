import 'dart:async';

import 'package:quadrapp_mobile/core/time/clock.dart';

/// Emite un tick cada cierto tiempo. Detrás de una función para poder
/// controlarlo en las pruebas.
typedef Ticker = Stream<void> Function();

Stream<void> _everySecond() =>
    Stream<void>.periodic(const Duration(seconds: 1));

/// Cuenta regresiva (por ejemplo, "puedes pedir otro código en 0:45").
///
/// El tiempo restante se calcula con el reloj **monótono** local, no con el del
/// teléfono ni contando ticks: si un tick se retrasa, la cuenta sigue exacta.
class Countdown {
  Countdown(this._clock, {this._ticker = _everySecond});

  final Clock _clock;
  final Ticker _ticker;

  /// Emite el tiempo restante de [total] al empezar y en cada tick, y termina
  /// al llegar a cero (el último valor emitido es `Duration.zero`). Cancelar la
  /// suscripción detiene el temporizador.
  Stream<Duration> run(Duration total) async* {
    final startedAt = _clock.monotonic();
    Duration remaining() {
      final elapsed = _clock.monotonic() - startedAt;
      final left = total - elapsed;
      return left.isNegative ? Duration.zero : left;
    }

    var left = remaining();
    yield left;
    if (left == Duration.zero) return;
    await for (final _ in _ticker()) {
      left = remaining();
      yield left;
      if (left == Duration.zero) return;
    }
  }
}

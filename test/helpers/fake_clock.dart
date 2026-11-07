import 'package:quadrapp_mobile/core/time/clock.dart';

/// Reloj controlable para pruebas: la hora y el tiempo monótono avanzan solo
/// con [advance].
class FakeClock implements Clock {
  FakeClock([DateTime? start])
    : _now = start ?? DateTime.utc(2026, 9, 28, 13, 42);

  DateTime _now;
  Duration _monotonic = Duration.zero;

  /// Avanza la hora y el tiempo monótono.
  void advance(Duration duration) {
    _now = _now.add(duration);
    _monotonic += duration;
  }

  /// Cambia solo la hora de pared (como si el usuario ajustara el reloj del
  /// teléfono): el tiempo monótono no se altera.
  // ignore: avoid_setters_without_getters
  set wallClock(DateTime value) => _now = value;

  @override
  DateTime now() => _now;

  @override
  Duration monotonic() => _monotonic;
}

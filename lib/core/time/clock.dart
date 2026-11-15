/// Reloj inyectable, para poder probar el tiempo.
abstract interface class Clock {
  /// Hora actual del dispositivo, en UTC.
  DateTime now();

  /// Tiempo monótono desde un origen arbitrario: solo sirve para medir cuánto
  /// pasó dentro de la misma ejecución de la app (no cambia si el usuario
  /// ajusta la hora del teléfono).
  Duration monotonic();
}

/// Reloj real.
class SystemClock implements Clock {
  SystemClock() : _stopwatch = Stopwatch()..start();

  final Stopwatch _stopwatch;

  @override
  DateTime now() => DateTime.now().toUtc();

  @override
  Duration monotonic() => _stopwatch.elapsed;
}

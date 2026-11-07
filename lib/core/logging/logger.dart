import 'dart:developer' as developer;

/// Registro de avisos. Nunca recibe contraseñas, códigos OTP, tokens ni el
/// header `Authorization`, ni datos personales.
// ignore: one_member_abstracts
abstract interface class Logger {
  void warning(String message, {Object? error});
}

/// Escribe en `dart:developer` (sin `print`).
class DeveloperLogger implements Logger {
  const DeveloperLogger();

  @override
  void warning(String message, {Object? error}) {
    developer.log(message, name: 'quadrapp', level: 900, error: error);
  }
}

/// No hace nada (pruebas).
class NoopLogger implements Logger {
  const NoopLogger();

  @override
  void warning(String message, {Object? error}) {}
}

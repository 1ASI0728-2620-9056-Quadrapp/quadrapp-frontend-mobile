/// Una respuesta que no se puede leer (campo faltante o de otro tipo). Los
/// mappers y datasources la lanzan; `guardResult` la convierte en
/// `ParseFailure`.
class ParseException implements Exception {
  const ParseException(this.message);

  final String message;

  @override
  String toString() => 'ParseException: $message';
}

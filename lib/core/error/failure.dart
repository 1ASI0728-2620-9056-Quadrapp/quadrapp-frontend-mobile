import 'package:equatable/equatable.dart';

/// Causa de un error, como dato. Nada de excepciones que crucen capas.
sealed class Failure extends Equatable {
  const Failure([this.message]);

  /// Texto técnico opcional (nunca se muestra al usuario tal cual; la UI elige
  /// un texto i18n según el tipo de falla).
  final String? message;

  @override
  List<Object?> get props => [message];
}

/// Sin conexión, tiempo de espera agotado o error de transporte.
final class NetworkFailure extends Failure {
  const NetworkFailure([super.message]);
}

/// 401: la sesión no es válida.
final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message]);
}

/// 403: sin permiso (por ejemplo, un correo sin vínculo institucional).
final class ForbiddenFailure extends Failure {
  const ForbiddenFailure([super.message]);
}

/// 400, 409 o 422: la petición no es válida o choca con una regla.
final class ValidationFailure extends Failure {
  const ValidationFailure([super.message, this.errors = const {}]);

  /// Errores por campo (`errors` de RFC 9457).
  final Map<String, List<String>> errors;

  @override
  List<Object?> get props => [message, errors];
}

/// 429: demasiadas solicitudes. La UI muestra una cuenta regresiva.
final class RateLimitedFailure extends Failure {
  const RateLimitedFailure({this.retryAfter, String? message}) : super(message);

  final Duration? retryAfter;

  @override
  List<Object?> get props => [message, retryAfter];
}

/// 404.
final class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message]);
}

/// 5xx.
final class ServerFailure extends Failure {
  const ServerFailure([super.message, this.statusCode]);

  final int? statusCode;

  @override
  List<Object?> get props => [message, statusCode];
}

/// La respuesta no se pudo leer: el contrato cambió o el JSON no coincide.
/// Distingue "el servidor falló" de "el contrato cambió".
final class ParseFailure extends Failure {
  const ParseFailure([super.message]);
}

/// Cualquier otra causa.
final class UnknownFailure extends Failure {
  const UnknownFailure([super.message]);
}

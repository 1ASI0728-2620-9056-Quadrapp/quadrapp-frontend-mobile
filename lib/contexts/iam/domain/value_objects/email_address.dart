import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// Correo del usuario, en minúsculas (docs/06: `users.email` es único y en
/// minúsculas).
class EmailAddress extends Equatable {
  const EmailAddress._(this.value);

  /// Longitud máxima que acepta el servidor (`users.email`, docs/06).
  static const int maxLength = 254;

  static final RegExp _shape = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  /// Correo válido: con `@`, un dominio con punto, sin espacios y de hasta
  /// [maxLength] caracteres.
  static Result<EmailAddress> create(String raw) {
    final value = raw.trim().toLowerCase();
    if (value.length > maxLength || !_shape.hasMatch(value)) {
      return const Err(
        ValidationFailure('El correo no tiene un formato válido.', {
          'email': ['invalid'],
        }),
      );
    }
    return Success(EmailAddress._(value));
  }

  final String value;

  /// Es el correo: no es un secreto, pero tampoco se registra en los logs.
  @override
  List<Object?> get props => [value];

  @override
  String toString() => 'EmailAddress(<redactado>)';
}

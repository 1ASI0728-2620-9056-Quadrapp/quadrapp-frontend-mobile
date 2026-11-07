import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// Token del dispositivo para recibir push (US33 esc. 2). Es un secreto: nunca
/// se registra en los logs, así que [toString] no lo muestra.
class PushToken extends Equatable {
  const PushToken._(this.value);

  /// Longitud máxima que acepta el servidor (`push_tokens.token`, docs/06).
  static const int maxLength = 512;

  /// Token válido: no vacío (sin contar espacios) y de hasta [maxLength].
  static Result<PushToken> create(String raw) {
    final value = raw.trim();
    if (value.isEmpty || value.length > maxLength) {
      return const Err(
        ValidationFailure('El token del dispositivo no es válido.'),
      );
    }
    return Success(PushToken._(value));
  }

  final String value;

  @override
  List<Object?> get props => [value];

  @override
  String toString() => 'PushToken(<redactado>)';
}

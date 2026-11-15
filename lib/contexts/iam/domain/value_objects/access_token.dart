import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// Token de acceso (`Authorization: Bearer`). Vive solo en memoria. Es un
/// secreto: [toString] no muestra su valor.
class AccessToken extends Equatable {
  const AccessToken._(this.value);

  /// Token no vacío.
  static Result<AccessToken> create(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return const Err(ValidationFailure('El token de acceso está vacío.'));
    }
    return Success(AccessToken._(value));
  }

  final String value;

  @override
  List<Object?> get props => [value];

  @override
  String toString() => 'AccessToken(<redactado>)';
}

import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// Token de refresco. Vive solo en el almacén seguro. Es un secreto:
/// [toString] no muestra su valor.
class RefreshToken extends Equatable {
  const RefreshToken._(this.value);

  /// Token no vacío.
  static Result<RefreshToken> create(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return const Err(ValidationFailure('El token de refresco está vacío.'));
    }
    return Success(RefreshToken._(value));
  }

  final String value;

  @override
  List<Object?> get props => [value];

  @override
  String toString() => 'RefreshToken(<redactado>)';
}

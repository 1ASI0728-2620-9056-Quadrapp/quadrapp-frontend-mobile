import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// Código de un solo uso (US01): 6 dígitos. Es un secreto: nunca se registra
/// en los logs, así que [toString] no lo muestra.
class OtpCode extends Equatable {
  const OtpCode._(this.value);

  static const int length = 6;

  static final RegExp _digits = RegExp(r'^\d{6}$');

  /// Código válido: exactamente [length] dígitos (se ignoran los espacios de
  /// los extremos).
  static Result<OtpCode> create(String raw) {
    final value = raw.trim();
    if (!_digits.hasMatch(value)) {
      return const Err(
        ValidationFailure('El código debe tener 6 dígitos.', {
          'code': ['6-digits'],
        }),
      );
    }
    return Success(OtpCode._(value));
  }

  final String value;

  @override
  List<Object?> get props => [value];

  @override
  String toString() => 'OtpCode(<redactado>)';
}

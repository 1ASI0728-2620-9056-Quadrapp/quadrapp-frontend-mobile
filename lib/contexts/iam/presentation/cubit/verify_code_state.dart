// US01 (esc. 2, 3), US03 (esc. 3), TS01 (esc. 3, 4)
import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/email_address.dart';

/// Aviso informativo de `/login/verify`.
enum VerifyNotice {
  /// Se envió un código nuevo.
  resent,

  /// Pedir otro código falló por la red.
  resendNetworkError,

  /// Pedir otro código falló por demasiadas solicitudes (429).
  resendRateLimited,

  /// Pedir otro código falló por otra causa.
  resendFailed,
}

/// Datos de `/login/verify`. El estado de la pantalla es un
/// `ViewState<VerifyForm>`:
///
/// - `ViewData`: se puede escribir el código; puede llevar un [notice] y la
///   cuenta regresiva de "Reenviar código" ([resendBlockedFor]).
/// - `ViewLoading(previous:)`: se está verificando el código.
/// - `ViewError(previous:)`: la verificación falló (401, red, otra causa).
///
/// El código escrito vive en el campo de texto, no aquí; el correo es un
/// `EmailAddress` cuyo `toString` está redactado.
class VerifyForm extends Equatable {
  const VerifyForm({
    required this.email,
    this.resendBlockedFor = Duration.zero,
    this.resending = false,
    this.notice,
  });

  /// El correo al que se envió el código (la pantalla lo muestra).
  final EmailAddress email;

  /// Cuánto falta para poder reenviar el código; cero si ya se puede.
  final Duration resendBlockedFor;

  /// Se está pidiendo un código nuevo.
  final bool resending;

  final VerifyNotice? notice;

  bool get canResend => !resending && resendBlockedFor == Duration.zero;

  VerifyForm copyWith({
    Duration? resendBlockedFor,
    bool? resending,
    VerifyNotice? notice,
    bool clearNotice = false,
  }) => VerifyForm(
    email: email,
    resendBlockedFor: resendBlockedFor ?? this.resendBlockedFor,
    resending: resending ?? this.resending,
    notice: clearNotice ? null : notice ?? this.notice,
  );

  @override
  List<Object?> get props => [email, resendBlockedFor, resending, notice];
}

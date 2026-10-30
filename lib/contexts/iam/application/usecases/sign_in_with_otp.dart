// US01, TS01
import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/entities/login_grant.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/entities/session.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/repositories/access_token_holder.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/repositories/auth_repository.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/repositories/session_store.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/email_address.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/otp_code.dart';
import 'package:quadrapp_mobile/core/network/failure_mapper.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

class SignInWithOtpParams extends Equatable {
  const SignInWithOtpParams({required this.email, required this.code});

  final String email;
  final String code;

  /// Ni el correo ni el código aparecen al convertir el objeto en texto.
  @override
  List<Object?> get props => [email, code];

  @override
  String toString() => 'SignInWithOtpParams(<redactado>)';
}

/// Inicia sesión con el correo y el código (US01 esc. 2 y 3).
///
/// - Un correo o un código con formato inválido falla con `ValidationFailure`
///   sin llamar al servidor.
/// - 401: el código es incorrecto, venció o agotó sus intentos
///   (`UnauthorizedFailure`); la app pide uno nuevo.
/// - Con un código válido, guarda el refresh token (almacén seguro) y el
///   usuario, y deja el access token solo en memoria. Se acepta cualquier rol.
class SignInWithOtp implements UseCase<Session, SignInWithOtpParams> {
  const SignInWithOtp({
    required this._auth,
    required this._sessions,
    required this._accessToken,
  });

  final AuthRepository _auth;
  final SessionStore _sessions;
  final AccessTokenHolder _accessToken;

  @override
  Future<Result<Session>> call(SignInWithOtpParams params) async {
    final EmailAddress email;
    switch (EmailAddress.create(params.email)) {
      case Err(:final failure):
        return Err(failure);
      case Success(:final value):
        email = value;
    }
    final OtpCode code;
    switch (OtpCode.create(params.code)) {
      case Err(:final failure):
        return Err(failure);
      case Success(:final value):
        code = value;
    }

    final LoginGrant grant;
    switch (await _auth.login(email, code)) {
      case Err(:final failure):
        return Err(failure);
      case Success(:final value):
        grant = value;
    }

    final saved = await guardResult(
      () => _sessions.save(
        StoredSession(
          session: grant.session,
          refreshToken: grant.refreshToken,
        ),
      ),
    );
    if (saved case Err(:final failure)) return Err(failure);
    _accessToken.replace(grant.accessToken);
    return Success(grant.session);
  }
}

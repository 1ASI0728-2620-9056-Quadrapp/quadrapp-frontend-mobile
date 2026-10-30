import 'package:quadrapp_mobile/contexts/iam/domain/entities/login_grant.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/entities/otp_challenge.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/access_token.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/email_address.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/otp_code.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/refresh_token.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// La autenticación contra el servidor (`/auth/*`).
abstract interface class AuthRepository {
  /// `POST /auth/otp`. Falla con `ForbiddenFailure` (403: el correo no es de
  /// una institución habilitada) o `RateLimitedFailure` (429, con
  /// `retryAfter`).
  Future<Result<OtpChallenge>> requestOtp(EmailAddress email);

  /// `POST /auth/login`. Falla con `UnauthorizedFailure` (401) si el código es
  /// incorrecto, venció o agotó sus intentos.
  Future<Result<LoginGrant>> login(EmailAddress email, OtpCode code);

  /// `POST /auth/refresh`. Falla con `UnauthorizedFailure` (401) si el refresh
  /// token venció o fue revocado.
  Future<Result<AccessToken>> refresh(RefreshToken refreshToken);

  /// `POST /auth/logout`: revoca esa sesión en el servidor.
  Future<Result<void>> logout(RefreshToken refreshToken);
}

// US01, TS01
import 'package:quadrapp_mobile/contexts/iam/domain/entities/otp_challenge.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/repositories/auth_repository.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/email_address.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

/// Pide el código de un solo uso al correo (US01 esc. 1, 4 y 5).
///
/// - Un correo con formato inválido falla con `ValidationFailure` sin llamar al
///   servidor.
/// - 403: el correo no es de una institución habilitada (`ForbiddenFailure`).
/// - 429: demasiadas solicitudes; `RateLimitedFailure.retryAfter` alimenta la
///   cuenta regresiva de la pantalla (TS01 esc. 2).
class RequestOtp implements UseCase<OtpChallenge, String> {
  const RequestOtp(this._auth);

  final AuthRepository _auth;

  @override
  Future<Result<OtpChallenge>> call(String email) async {
    return switch (EmailAddress.create(email)) {
      Success(:final value) => _auth.requestOtp(value),
      Err(:final failure) => Err(failure),
    };
  }
}

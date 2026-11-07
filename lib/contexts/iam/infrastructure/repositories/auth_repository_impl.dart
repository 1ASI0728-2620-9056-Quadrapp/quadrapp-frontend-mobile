import 'package:quadrapp_mobile/contexts/iam/domain/entities/login_grant.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/entities/otp_challenge.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/repositories/auth_repository.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/access_token.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/email_address.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/otp_code.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/refresh_token.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/datasources/auth_remote_datasource.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/dto/auth_dtos.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/mappers/iam_mapper.dart';
import 'package:quadrapp_mobile/core/network/failure_mapper.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';

/// La autenticación del servidor. Cualquier falla de infraestructura (401,
/// 403, 429 con `retryAfter`, red, JSON ilegible) llega como una `Failure`.
class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required this._remote,
    required this._mapper,
    required this._clock,
  });

  final AuthRemoteDataSource _remote;
  final IamMapper _mapper;
  final Clock _clock;

  @override
  Future<Result<OtpChallenge>> requestOtp(EmailAddress email) =>
      guardResult(() async {
        final dto = await _remote.requestOtp(OtpRequestDto(email: email.value));
        return _mapper.toChallenge(dto, email, receivedAt: _clock.monotonic());
      });

  @override
  Future<Result<LoginGrant>> login(EmailAddress email, OtpCode code) =>
      guardResult(
        () async => _mapper.toGrant(
          await _remote.login(
            LoginRequestDto(email: email.value, code: code.value),
          ),
        ),
      );

  @override
  Future<Result<AccessToken>> refresh(RefreshToken refreshToken) => guardResult(
    () async => _mapper.toAccessToken(
      await _remote.refresh(
        RefreshTokenRequestDto(refreshToken: refreshToken.value),
      ),
    ),
  );

  @override
  Future<Result<void>> logout(RefreshToken refreshToken) => guardResult(
    () => _remote.logout(
      RefreshTokenRequestDto(refreshToken: refreshToken.value),
    ),
  );
}

import 'package:quadrapp_mobile/contexts/iam/infrastructure/dto/auth_dtos.dart';

/// Origen remoto de la autenticación (HTTP o mock): mismos errores, mismos
/// formatos, mismas garantías.
abstract interface class AuthRemoteDataSource {
  /// `POST /auth/otp`.
  Future<OtpChallengeDto> requestOtp(OtpRequestDto request);

  /// `POST /auth/login`.
  Future<LoginResponseDto> login(LoginRequestDto request);

  /// `POST /auth/refresh`.
  Future<RefreshResponseDto> refresh(RefreshTokenRequestDto request);

  /// `POST /auth/logout` (lleva `Authorization`).
  Future<void> logout(RefreshTokenRequestDto request);
}

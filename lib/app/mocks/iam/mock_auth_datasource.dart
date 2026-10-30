import 'package:quadrapp_mobile/app/mocks/iam/mock_iam_state.dart';
import 'package:quadrapp_mobile/app/mocks/mock_errors.dart';
import 'package:quadrapp_mobile/app/mocks/mock_world.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/datasources/auth_remote_datasource.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/dto/auth_dtos.dart';

final RegExp _emailShape = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
final RegExp _sixDigits = RegExp(r'^\d{6}$');

/// La autenticación desde [MockWorld]. El JSON sigue docs/07 y se lee con los
/// mismos DTO que el datasource HTTP.
///
/// - `POST /auth/otp`: correos de `upc.edu.pe` reciben código (202 con la
///   vigencia); otro dominio, 403; formato inválido, 400; con
///   `MockControls.force429`, 429 con `retryAfterSec`.
/// - `POST /auth/login`: solo sirve el código `123456` pedido antes, vigente y
///   con intentos disponibles; es de un solo uso. Si no, 401.
/// - `POST /auth/refresh`: 401 si el refresh token no está vigente o con
///   `MockControls.sessionExpired`.
/// - `POST /auth/logout`: lleva sesión (aplica `force401`) y revoca el refresh
///   token.
class MockAuthRemoteDataSource implements AuthRemoteDataSource {
  const MockAuthRemoteDataSource(this._world);

  final MockWorld _world;

  MockIamState get _state => _world.iam;

  @override
  Future<OtpChallengeDto> requestOtp(OtpRequestDto request) async {
    await _world.gate(isAuth: true);
    final email = request.email.trim().toLowerCase();
    if (!_emailShape.hasMatch(email)) _invalid('email');
    if (!email.endsWith('@${_state.domain}')) {
      throw mockHttpError(
        403,
        title: 'Forbidden',
        detail: 'El correo no corresponde a una institución habilitada.',
      );
    }
    _state.otpIssuedAt[email] = _world.clock.now();
    _state.failedAttempts[email] = 0;
    return OtpChallengeDto(
      expiresInSec: MockIamState.otpValidity.inSeconds,
    );
  }

  @override
  Future<LoginResponseDto> login(LoginRequestDto request) async {
    await _world.gate(isAuth: true, rateLimited: false);
    final email = request.email.trim().toLowerCase();
    if (!_emailShape.hasMatch(email)) _invalid('email');
    if (!_sixDigits.hasMatch(request.code)) _invalid('code');

    final issuedAt = _state.otpIssuedAt[email];
    final attempts = _state.failedAttempts[email] ?? 0;
    final alive =
        issuedAt != null &&
        _world.clock.now().difference(issuedAt) <= MockIamState.otpValidity &&
        attempts < MockIamState.maxAttempts;
    if (!alive || request.code != _state.validCode) {
      if (issuedAt != null) _state.failedAttempts[email] = attempts + 1;
      // Incorrecto, vencido o con intentos agotados: una sola respuesta.
      throw mockHttpError(401, title: 'Unauthorized');
    }

    // De un solo uso.
    _state.otpIssuedAt.remove(email);
    final role = _state.roleFor(email);
    final fullName = _state.fullNameFor(email);
    return LoginResponseDto.fromJson({
      'accessToken': _state.newAccessToken(role: role),
      'refreshToken': _state.newRefreshToken(role: role),
      'user': {
        'id': _state.userIdFor(email),
        'email': email,
        'fullName': ?fullName,
        'role': role,
        'institutionId': _state.institutionId,
        'institutionName': _state.institutionName,
      },
    });
  }

  @override
  Future<RefreshResponseDto> refresh(RefreshTokenRequestDto request) async {
    await _world.gate(isAuth: true, rateLimited: false);
    if (_world.controls.sessionExpired ||
        !_state.refreshTokens.contains(request.refreshToken)) {
      throw mockHttpError(401, title: 'Unauthorized');
    }
    return RefreshResponseDto.fromJson({
      'accessToken': _state.newAccessToken(
        role: _state.roleForRefreshToken(request.refreshToken) ?? 'DRIVER',
      ),
    });
  }

  @override
  Future<void> logout(RefreshTokenRequestDto request) async {
    await _world.gate();
    if (!_state.refreshTokens.remove(request.refreshToken)) {
      throw mockHttpError(401, title: 'Unauthorized');
    }
  }

  Never _invalid(String field) => throw mockHttpError(
    400,
    title: 'Bad Request',
    extra: {
      'errors': {
        field: ['invalid'],
      },
    },
  );
}

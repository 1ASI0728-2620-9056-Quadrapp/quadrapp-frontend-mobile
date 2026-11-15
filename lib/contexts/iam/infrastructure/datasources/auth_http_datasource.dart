import 'package:dio/dio.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/datasources/auth_remote_datasource.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/dto/auth_dtos.dart';
import 'package:quadrapp_mobile/core/network/parse_exception.dart';

Map<String, dynamic> _asObject(Object? data, String what) {
  if (data is! Map<String, dynamic>) {
    throw ParseException('$what no es un objeto JSON.');
  }
  return data;
}

/// `/iam/auth/*` del backend. Las cuatro rutas son públicas (sin
/// `Authorization`; ver `AuthInterceptor`): el servidor rechaza un token
/// vencido aunque la ruta sea pública.
///
/// Traduce las respuestas del backend a los DTO de la app, que también usan
/// los mocks:
/// - `request-otp` responde solo un mensaje: la vigencia del código es la del
///   servidor ([otpLifetimeSeconds], `quadrapp.iam.otp-expiration-minutes`).
/// - `sign-in` y `refresh` responden `AuthenticatedUserResource`
///   (`{ user, accessToken, refreshToken, expiresIn, expiresAt }`). El usuario
///   no trae el nombre de la institución: se pide a
///   `GET /iam/institutions/{id}` con el token recién emitido; si falla, la
///   sesión sigue sin nombre de institución.
/// - `refresh` **rota** el refresh token: el nuevo viaja en
///   [RefreshResponseDto.refreshToken].
class AuthHttpDataSource implements AuthRemoteDataSource {
  const AuthHttpDataSource(this._dio);

  final Dio _dio;

  /// Vigencia del código OTP en el backend (5 minutos por defecto).
  static const otpLifetimeSeconds = 300;

  @override
  Future<OtpChallengeDto> requestOtp(OtpRequestDto request) async {
    await _dio.post<Object?>('/iam/auth/request-otp', data: request.toJson());
    return const OtpChallengeDto(expiresInSec: otpLifetimeSeconds);
  }

  @override
  Future<LoginResponseDto> login(LoginRequestDto request) async {
    final response = await _dio.post<Object?>(
      '/iam/auth/sign-in',
      data: {'email': request.email, 'otpCode': request.code},
    );
    final body = _asObject(response.data, 'La sesión');
    final accessToken = body['accessToken'];
    final refreshToken = body['refreshToken'];
    final user = _asObject(body['user'], 'El usuario');
    final id = user['id'];
    final institutionId = user['institutionId'];
    if (accessToken is! String ||
        refreshToken is! String ||
        id is! num ||
        institutionId is! num) {
      throw const ParseException('La sesión no tiene el formato esperado.');
    }
    return LoginResponseDto(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: UserDto(
        id: id.toInt(),
        email: user['email'] as String? ?? '',
        fullName: user['fullName'] as String?,
        role: user['role'] as String? ?? '',
        institutionId: institutionId.toInt(),
        institutionName: await _institutionName(
          institutionId.toInt(),
          accessToken,
        ),
      ),
    );
  }

  /// El nombre de la institución; vacío si no se pudo leer.
  Future<String> _institutionName(int institutionId, String accessToken) async {
    try {
      final response = await _dio.get<Object?>(
        '/iam/institutions/$institutionId',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      final data = response.data;
      final name = data is Map<String, dynamic> ? data['name'] : null;
      return name is String ? name : '';
    } on DioException {
      return '';
    }
  }

  @override
  Future<RefreshResponseDto> refresh(RefreshTokenRequestDto request) async {
    final response = await _dio.post<Object?>(
      '/iam/auth/refresh',
      data: request.toJson(),
    );
    return RefreshResponseDto.fromJson(
      _asObject(response.data, 'La respuesta'),
    );
  }

  @override
  Future<void> logout(RefreshTokenRequestDto request) async {
    await _dio.post<Object?>('/iam/auth/sign-out', data: request.toJson());
  }
}

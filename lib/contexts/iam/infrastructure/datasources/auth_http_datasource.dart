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

/// `/auth/*`. Las cuatro rutas excepto `/auth/logout` son públicas (sin
/// `Authorization`; ver `AuthInterceptor`).
class AuthHttpDataSource implements AuthRemoteDataSource {
  const AuthHttpDataSource(this._dio);

  final Dio _dio;

  @override
  Future<OtpChallengeDto> requestOtp(OtpRequestDto request) async {
    final response = await _dio.post<Object?>(
      '/auth/otp',
      data: request.toJson(),
    );
    return OtpChallengeDto.fromJson(_asObject(response.data, 'La respuesta'));
  }

  @override
  Future<LoginResponseDto> login(LoginRequestDto request) async {
    final response = await _dio.post<Object?>(
      '/auth/login',
      data: request.toJson(),
    );
    return LoginResponseDto.fromJson(_asObject(response.data, 'La sesión'));
  }

  @override
  Future<RefreshResponseDto> refresh(RefreshTokenRequestDto request) async {
    final response = await _dio.post<Object?>(
      '/auth/refresh',
      data: request.toJson(),
    );
    return RefreshResponseDto.fromJson(
      _asObject(response.data, 'La respuesta'),
    );
  }

  @override
  Future<void> logout(RefreshTokenRequestDto request) async {
    await _dio.post<Object?>('/auth/logout', data: request.toJson());
  }
}

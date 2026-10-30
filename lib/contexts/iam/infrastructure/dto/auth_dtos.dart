import 'package:json_annotation/json_annotation.dart';

part 'auth_dtos.g.dart';

/// El cuerpo de `POST /auth/otp`.
@JsonSerializable()
class OtpRequestDto {
  const OtpRequestDto({required this.email});

  factory OtpRequestDto.fromJson(Map<String, dynamic> json) =>
      _$OtpRequestDtoFromJson(json);

  final String email;

  Map<String, dynamic> toJson() => _$OtpRequestDtoToJson(this);
}

/// La respuesta 202 de `POST /auth/otp`.
@JsonSerializable()
class OtpChallengeDto {
  const OtpChallengeDto({required this.expiresInSec});

  factory OtpChallengeDto.fromJson(Map<String, dynamic> json) =>
      _$OtpChallengeDtoFromJson(json);

  /// Vigencia del código, en segundos.
  final int expiresInSec;

  Map<String, dynamic> toJson() => _$OtpChallengeDtoToJson(this);
}

/// El cuerpo de `POST /auth/login`.
@JsonSerializable()
class LoginRequestDto {
  const LoginRequestDto({required this.email, required this.code});

  factory LoginRequestDto.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestDtoFromJson(json);

  final String email;
  final String code;

  Map<String, dynamic> toJson() => _$LoginRequestDtoToJson(this);
}

/// El usuario de la respuesta de login (y lo que se guarda en el dispositivo).
@JsonSerializable()
class UserDto {
  const UserDto({
    required this.id,
    required this.email,
    required this.role,
    required this.institutionId,
    required this.institutionName,
    this.fullName,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) =>
      _$UserDtoFromJson(json);

  final int id;
  final String email;

  /// `users.full_name`: opcional (`null` o ausente = sin nombre).
  final String? fullName;

  /// `DRIVER`, `OPERATOR` o `ADMIN`; un valor no reconocido se trata como
  /// `DRIVER`.
  final String role;
  final int institutionId;
  final String institutionName;

  Map<String, dynamic> toJson() => _$UserDtoToJson(this);
}

/// La respuesta 200 de `POST /auth/login`.
@JsonSerializable(explicitToJson: true)
class LoginResponseDto {
  const LoginResponseDto({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory LoginResponseDto.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseDtoFromJson(json);

  final String accessToken;
  final String refreshToken;
  final UserDto user;

  Map<String, dynamic> toJson() => _$LoginResponseDtoToJson(this);
}

/// El cuerpo de `POST /auth/refresh` y de `POST /auth/logout`.
@JsonSerializable()
class RefreshTokenRequestDto {
  const RefreshTokenRequestDto({required this.refreshToken});

  factory RefreshTokenRequestDto.fromJson(Map<String, dynamic> json) =>
      _$RefreshTokenRequestDtoFromJson(json);

  final String refreshToken;

  Map<String, dynamic> toJson() => _$RefreshTokenRequestDtoToJson(this);
}

/// La respuesta 200 de `POST /auth/refresh`: el refresh token no rota.
@JsonSerializable()
class RefreshResponseDto {
  const RefreshResponseDto({required this.accessToken});

  factory RefreshResponseDto.fromJson(Map<String, dynamic> json) =>
      _$RefreshResponseDtoFromJson(json);

  final String accessToken;

  Map<String, dynamic> toJson() => _$RefreshResponseDtoToJson(this);
}

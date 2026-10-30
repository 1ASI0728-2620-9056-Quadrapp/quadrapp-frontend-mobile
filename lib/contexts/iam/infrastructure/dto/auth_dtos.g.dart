// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OtpRequestDto _$OtpRequestDtoFromJson(Map<String, dynamic> json) =>
    OtpRequestDto(email: json['email'] as String);

Map<String, dynamic> _$OtpRequestDtoToJson(OtpRequestDto instance) =>
    <String, dynamic>{'email': instance.email};

OtpChallengeDto _$OtpChallengeDtoFromJson(Map<String, dynamic> json) =>
    OtpChallengeDto(expiresInSec: (json['expiresInSec'] as num).toInt());

Map<String, dynamic> _$OtpChallengeDtoToJson(OtpChallengeDto instance) =>
    <String, dynamic>{'expiresInSec': instance.expiresInSec};

LoginRequestDto _$LoginRequestDtoFromJson(Map<String, dynamic> json) =>
    LoginRequestDto(
      email: json['email'] as String,
      code: json['code'] as String,
    );

Map<String, dynamic> _$LoginRequestDtoToJson(LoginRequestDto instance) =>
    <String, dynamic>{'email': instance.email, 'code': instance.code};

UserDto _$UserDtoFromJson(Map<String, dynamic> json) => UserDto(
  id: (json['id'] as num).toInt(),
  email: json['email'] as String,
  role: json['role'] as String,
  institutionId: (json['institutionId'] as num).toInt(),
  institutionName: json['institutionName'] as String,
  fullName: json['fullName'] as String?,
);

Map<String, dynamic> _$UserDtoToJson(UserDto instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'fullName': instance.fullName,
  'role': instance.role,
  'institutionId': instance.institutionId,
  'institutionName': instance.institutionName,
};

LoginResponseDto _$LoginResponseDtoFromJson(Map<String, dynamic> json) =>
    LoginResponseDto(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      user: UserDto.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$LoginResponseDtoToJson(LoginResponseDto instance) =>
    <String, dynamic>{
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'user': instance.user.toJson(),
    };

RefreshTokenRequestDto _$RefreshTokenRequestDtoFromJson(
  Map<String, dynamic> json,
) => RefreshTokenRequestDto(refreshToken: json['refreshToken'] as String);

Map<String, dynamic> _$RefreshTokenRequestDtoToJson(
  RefreshTokenRequestDto instance,
) => <String, dynamic>{'refreshToken': instance.refreshToken};

RefreshResponseDto _$RefreshResponseDtoFromJson(Map<String, dynamic> json) =>
    RefreshResponseDto(accessToken: json['accessToken'] as String);

Map<String, dynamic> _$RefreshResponseDtoToJson(RefreshResponseDto instance) =>
    <String, dynamic>{'accessToken': instance.accessToken};

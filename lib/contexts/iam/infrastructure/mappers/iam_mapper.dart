import 'package:quadrapp_mobile/contexts/iam/domain/entities/institution.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/entities/login_grant.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/entities/otp_challenge.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/entities/session.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/access_token.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/email_address.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/refresh_token.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/user_role.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/dto/auth_dtos.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/logging/logger.dart';
import 'package:quadrapp_mobile/core/network/parse_exception.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// DTO <-> entidades del dominio.
///
/// - Un rol que la app no reconoce se trata como `DRIVER` (el de menor
///   privilegio; la sesión no se rechaza ni se rompe la pantalla) y deja un
///   aviso sin datos personales.
/// - Una respuesta con un campo ilegible (correo inválido, token vacío) es un
///   `ParseException` (→ `ParseFailure`).
class IamMapper {
  const IamMapper(this._logger);

  final Logger _logger;

  OtpChallenge toChallenge(
    OtpChallengeDto dto,
    EmailAddress email, {
    required Duration receivedAt,
  }) {
    final seconds = dto.expiresInSec < 0 ? 0 : dto.expiresInSec;
    return OtpChallenge(
      email: email,
      expiresIn: Duration(seconds: seconds),
      receivedAt: receivedAt,
    );
  }

  LoginGrant toGrant(LoginResponseDto dto) => LoginGrant(
    session: toSession(dto.user),
    accessToken: _required(AccessToken.create(dto.accessToken), 'accessToken'),
    refreshToken: _required(
      RefreshToken.create(dto.refreshToken),
      'refreshToken',
    ),
  );

  Session toSession(UserDto dto) => Session(
    userId: UserId(dto.id),
    email: _required(EmailAddress.create(dto.email), 'email'),
    fullName: _cleanName(dto.fullName),
    role: parseRole(dto.role),
    institution: Institution(
      id: InstitutionId(dto.institutionId),
      name: dto.institutionName,
    ),
  );

  UserDto toUserDto(Session session) => UserDto(
    id: session.userId.value,
    email: session.email.value,
    fullName: session.fullName,
    role: roleToApi(session.role),
    institutionId: session.institution.id.value,
    institutionName: session.institution.name,
  );

  /// Un nombre vacío o de solo espacios es "sin nombre".
  String? _cleanName(String? raw) {
    final name = raw?.trim();
    return name == null || name.isEmpty ? null : name;
  }

  AccessToken toAccessToken(RefreshResponseDto dto) =>
      _required(AccessToken.create(dto.accessToken), 'accessToken');

  /// `DRIVER`, `OPERATOR` o `ADMIN`, sin distinguir mayúsculas; otro valor es
  /// `DRIVER`.
  UserRole parseRole(String raw) {
    switch (raw.toUpperCase()) {
      case 'DRIVER':
        return UserRole.driver;
      case 'OPERATOR':
        return UserRole.operator;
      case 'ADMIN':
        return UserRole.admin;
    }
    _logger.warning('Rol no reconocido "$raw": se usa DRIVER');
    return UserRole.driver;
  }

  String roleToApi(UserRole role) => switch (role) {
    UserRole.driver => 'DRIVER',
    UserRole.operator => 'OPERATOR',
    UserRole.admin => 'ADMIN',
  };

  T _required<T>(Result<T> result, String field) => switch (result) {
    Success(:final value) => value,
    Err() => throw ParseException('El campo $field no es válido.'),
  };
}

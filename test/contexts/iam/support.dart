import 'package:quadrapp_mobile/contexts/iam/domain/entities/institution.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/entities/login_grant.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/entities/session.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/access_token.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/email_address.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/refresh_token.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/user_role.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

EmailAddress email([String value = 'conductor@upc.edu.pe']) =>
    EmailAddress.create(value).valueOrNull ?? (throw StateError('correo'));

AccessToken accessToken([String value = 'access-1']) =>
    AccessToken.create(value).valueOrNull ?? (throw StateError('access'));

RefreshToken refreshToken([String value = 'refresh-1']) =>
    RefreshToken.create(value).valueOrNull ?? (throw StateError('refresh'));

Session sampleSession({UserRole role = UserRole.driver}) => Session(
  userId: const UserId(1),
  email: email(),
  role: role,
  institution: const Institution(
    id: InstitutionId(1),
    name: 'Universidad de prueba',
  ),
);

LoginGrant sampleGrant({UserRole role = UserRole.driver}) => LoginGrant(
  session: sampleSession(role: role),
  accessToken: accessToken(),
  refreshToken: refreshToken(),
);

StoredSession sampleStored({UserRole role = UserRole.driver}) => StoredSession(
  session: sampleSession(role: role),
  refreshToken: refreshToken(),
);

/// `POST /auth/login` (200) con el formato de docs/07.
Map<String, Object?> loginJson({
  String role = 'DRIVER',
  String accessToken = 'access-1',
  String refreshToken = 'refresh-1',
  String userEmail = 'conductor@upc.edu.pe',
}) => {
  'accessToken': accessToken,
  'refreshToken': refreshToken,
  'user': {
    'id': 1,
    'email': userEmail,
    'role': role,
    'institutionId': 1,
    'institutionName': 'Universidad de prueba',
  },
};

// US01, US03
import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/entities/institution.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/email_address.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/refresh_token.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/user_role.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

/// La sesión del usuario: quién es, con qué rol y en qué institución. No
/// contiene tokens (esos viven aparte: el de acceso en memoria y el de
/// refresco en el almacén seguro).
class Session extends Equatable {
  const Session({
    required this.userId,
    required this.email,
    required this.role,
    required this.institution,
    this.fullName,
  });

  final UserId userId;
  final EmailAddress email;
  final UserRole role;
  final Institution institution;

  /// El nombre completo del usuario, si lo tiene. Nunca se deriva del correo:
  /// sin nombre, la app saluda sin nombre.
  final String? fullName;

  @override
  List<Object?> get props => [userId.value, email, role, institution, fullName];
}

/// Lo que persiste en el dispositivo para que la sesión siga vigente al volver
/// a abrir la app (US01 esc. 6): la sesión y el token de refresco.
class StoredSession extends Equatable {
  const StoredSession({required this.session, required this.refreshToken});

  final Session session;
  final RefreshToken refreshToken;

  @override
  List<Object?> get props => [session, refreshToken];
}

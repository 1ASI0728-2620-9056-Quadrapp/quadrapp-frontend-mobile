// US01
import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/entities/session.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/access_token.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/refresh_token.dart';

/// Lo que entrega el servidor al iniciar sesión con un código válido.
class LoginGrant extends Equatable {
  const LoginGrant({
    required this.session,
    required this.accessToken,
    required this.refreshToken,
  });

  final Session session;
  final AccessToken accessToken;
  final RefreshToken refreshToken;

  @override
  List<Object?> get props => [session, accessToken, refreshToken];
}

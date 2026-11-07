import 'package:quadrapp_mobile/contexts/iam/application/usecases/refresh_session.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/repositories/access_token_holder.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/network/auth_interceptor.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

/// Conecta el `AuthInterceptor` (core) con `iam`: el token de acceso sale del
/// `AccessTokenHolder` (memoria) y el refresh lo hace `RefreshSession`.
///
/// Traduce el resultado a lo que el interceptor necesita distinguir:
/// - token nuevo → `Refreshed`;
/// - el servidor lo rechazó (401) → `Rejected` (la sesión expiró; US03);
/// - cualquier otra falla (sin red, 5xx) → `Unavailable` (la sesión se
///   conserva).
class SessionTokenSource implements AuthTokenSource {
  const SessionTokenSource({
    required this._accessToken,
    required this._refresh,
  });

  final AccessTokenHolder _accessToken;
  final RefreshSession _refresh;

  @override
  String? get accessToken => _accessToken.current?.value;

  @override
  Future<TokenRefresh> refreshAccessToken() async {
    return switch (await _refresh(const NoParams())) {
      Success(:final value) => Refreshed(value.value),
      Err(failure: UnauthorizedFailure()) => const Rejected(),
      Err() => const Unavailable(),
    };
  }
}

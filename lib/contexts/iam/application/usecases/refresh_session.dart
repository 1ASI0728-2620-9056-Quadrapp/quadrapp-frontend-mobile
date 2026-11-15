// US01 (esc. 6), US03, TS01 (esc. 5 y 6)
import 'package:quadrapp_mobile/contexts/iam/application/usecases/expire_session.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/repositories/access_token_holder.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/repositories/auth_repository.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/repositories/session_store.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/access_token.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/refresh_token.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/network/failure_mapper.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

/// Renueva el token de acceso con el token de refresco.
///
/// - **Un solo intento** por ronda: no reintenta por su cuenta.
/// - **Compartido**: si varias peticiones fallan a la vez y llaman a esto,
///   todas esperan el mismo refresh (una sola llamada al servidor).
/// - Si el servidor lo rechaza (401), la sesión expiró: llama a
///   [ExpireSession] y devuelve `UnauthorizedFailure`.
/// - Si no se pudo intentar (sin red, 5xx), la sesión se conserva y devuelve
///   esa falla: perder la señal no cierra la sesión.
class RefreshSession implements UseCase<AccessToken, NoParams> {
  RefreshSession({
    required this._auth,
    required this._sessions,
    required this._accessToken,
    required this._expire,
  });

  final AuthRepository _auth;
  final SessionStore _sessions;
  final AccessTokenHolder _accessToken;
  final ExpireSession _expire;

  Future<Result<AccessToken>>? _inFlight;

  @override
  Future<Result<AccessToken>> call(NoParams params) =>
      _inFlight ??= _refresh().whenComplete(() => _inFlight = null);

  Future<Result<AccessToken>> _refresh() async {
    final RefreshToken refreshToken;
    switch (await guardResult(
      () async => (await _sessions.read())?.refreshToken,
    )) {
      case Err(:final failure):
        return Err(failure);
      case Success(value: null):
        // Sin token de refresco no hay sesión que renovar.
        return const Err(UnauthorizedFailure());
      case Success(:final value?):
        refreshToken = value;
    }

    final result = await _auth.refresh(refreshToken);
    switch (result) {
      case Success(:final value):
        _accessToken.replace(value);
      case Err(failure: UnauthorizedFailure()):
        await _expire(const NoParams());
      case Err():
        break;
    }
    return result;
  }
}

// US02
import 'package:quadrapp_mobile/contexts/iam/domain/repositories/access_token_holder.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/repositories/auth_repository.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/repositories/session_store.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/network/failure_mapper.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

/// Revoca la sesión en el servidor (`POST /auth/logout`, US02 esc. 1). Es de
/// mejor esfuerzo: la usa `composition/sign_out` y no bloquea el cierre.
///
/// Un 401 cuenta como éxito: la sesión ya no era válida, que es lo que se
/// quería. Sin refresh token guardado, no hay nada que revocar.
class RevokeSession implements UseCase<void, NoParams> {
  const RevokeSession({required this._auth, required this._sessions});

  final AuthRepository _auth;
  final SessionStore _sessions;

  @override
  Future<Result<void>> call(NoParams params) async {
    final stored = await guardResult(_sessions.read);
    if (stored case Err(:final failure)) return Err(failure);
    final token = stored.valueOrNull?.refreshToken;
    if (token == null) return const Success<void>(null);

    final result = await _auth.logout(token);
    return result.failureOrNull is UnauthorizedFailure
        ? const Success<void>(null)
        : result;
  }
}

/// Borra en el dispositivo el usuario, el refresh token y el access token. No
/// avisa de nada: es el paso de limpieza de `composition/sign_out`.
class ClearSession implements UseCase<void, NoParams> {
  const ClearSession({required this._sessions, required this._accessToken});

  final SessionStore _sessions;
  final AccessTokenHolder _accessToken;

  @override
  Future<Result<void>> call(NoParams params) => guardResult(() async {
    _accessToken.clear();
    await _sessions.clear();
  });
}

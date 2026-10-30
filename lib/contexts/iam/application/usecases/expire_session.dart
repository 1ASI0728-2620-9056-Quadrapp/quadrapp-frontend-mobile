// US03
import 'package:quadrapp_mobile/contexts/iam/domain/repositories/access_token_holder.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/repositories/session_events.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/repositories/session_store.dart';
import 'package:quadrapp_mobile/core/network/failure_mapper.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

/// La sesión expiró (el servidor rechazó el refresh token): borra el usuario,
/// el refresh token y el access token, y avisa para que la app muestre el
/// mensaje y pida iniciar sesión de nuevo (US03 esc. 1 y 2).
///
/// Es idempotente: si ya no había sesión, no avisa otra vez. El resto de la
/// limpieza (token push, cachés, estacionamiento elegido) la hace
/// `composition/sign_out` con el motivo `sessionExpired`.
class ExpireSession implements UseCase<void, NoParams> {
  const ExpireSession({
    required this._sessions,
    required this._accessToken,
    required this._events,
  });

  final SessionStore _sessions;
  final AccessTokenHolder _accessToken;
  final SessionEvents _events;

  @override
  Future<Result<void>> call(NoParams params) => guardResult(() async {
    final hadSession =
        _accessToken.current != null || await _sessions.read() != null;
    _accessToken.clear();
    await _sessions.clear();
    if (hadSession) _events.notifyExpired();
  });
}

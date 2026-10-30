// US01 (esc. 6)
import 'package:quadrapp_mobile/contexts/iam/domain/entities/session.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/repositories/session_store.dart';
import 'package:quadrapp_mobile/core/network/failure_mapper.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

/// Al abrir la app, recupera la sesión guardada sin pedir un código nuevo
/// (US01 esc. 6) y sin llamar al servidor: abre aunque no haya red.
///
/// Devuelve `null` si no hay sesión (la app va a `/login`). El token de acceso
/// no se restaura (solo vive en memoria): la primera petición protegida recibe
/// un 401 y se renueva con el token de refresco.
class RestoreSession implements UseCase<Session?, NoParams> {
  const RestoreSession(this._sessions);

  final SessionStore _sessions;

  @override
  Future<Result<Session?>> call(NoParams params) =>
      guardResult(() async => (await _sessions.read())?.session);
}

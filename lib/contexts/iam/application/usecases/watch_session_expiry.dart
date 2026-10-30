// US03
import 'package:quadrapp_mobile/contexts/iam/domain/entities/session_expired.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/repositories/session_events.dart';

/// Los avisos de sesión expirada (US03 esc. 2): la app muestra el mensaje y
/// redirige a `/login?reason=expired`.
class WatchSessionExpiry {
  const WatchSessionExpiry(this._events);

  final SessionEvents _events;

  Stream<SessionExpired> call() => _events.expired;
}

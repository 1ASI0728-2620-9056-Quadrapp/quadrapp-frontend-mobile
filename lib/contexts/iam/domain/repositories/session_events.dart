import 'package:quadrapp_mobile/contexts/iam/domain/entities/session_expired.dart';

/// Avisos sobre la sesión. Hoy solo uno: que expiró (US03).
abstract interface class SessionEvents {
  Stream<SessionExpired> get expired;

  void notifyExpired();
}

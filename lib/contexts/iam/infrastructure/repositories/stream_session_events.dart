import 'dart:async';

import 'package:quadrapp_mobile/contexts/iam/domain/entities/session_expired.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/repositories/session_events.dart';

/// Los avisos de sesión con un `StreamController` de difusión: cualquier
/// pantalla o el router pueden escuchar sin conocerse entre sí.
class StreamSessionEvents implements SessionEvents {
  final StreamController<SessionExpired> _expired =
      StreamController<SessionExpired>.broadcast();

  @override
  Stream<SessionExpired> get expired => _expired.stream;

  @override
  void notifyExpired() {
    if (!_expired.isClosed) _expired.add(const SessionExpired());
  }

  Future<void> dispose() => _expired.close();
}

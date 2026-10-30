import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:quadrapp_mobile/contexts/notifications/application/usecases/pending_token_removal_usecases.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

/// Reintenta la baja pendiente del token push **al arrancar la app y cada vez
/// que vuelve a primer plano** (docs/04). No usa ningún paquete de
/// conectividad ni necesita sesión.
///
/// Si ya hay un reintento en curso, ignora el aviso: nunca hay dos a la vez.
/// Un fallo no se propaga: el registro se conserva para el próximo intento.
class PendingRemovalRetrier with WidgetsBindingObserver {
  PendingRemovalRetrier(this._retry);

  final RetryPendingTokenRemoval _retry;

  bool _running = false;

  /// Empieza a escuchar el ciclo de vida y hace el primer intento (el del
  /// arranque).
  Future<void> start() {
    WidgetsBinding.instance.addObserver(this);
    return retry();
  }

  void dispose() => WidgetsBinding.instance.removeObserver(this);

  /// Un intento. Es público para poder probarlo y para el arranque.
  Future<void> retry() async {
    if (_running) return;
    _running = true;
    try {
      await _retry(const NoParams());
    } finally {
      _running = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Sin esperar: el ciclo de vida no debe bloquearse.
      unawaited(retry());
    }
  }
}

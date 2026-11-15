// US03
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:quadrapp_mobile/composition/sign_out/sign_out.dart';
import 'package:quadrapp_mobile/contexts/iam/iam.dart';

/// Qué hace la app cuando la sesión expira (US03).
///
/// `iam` avisa con `WatchSessionExpiry` (lo emite `ExpireSession` cuando el
/// servidor rechaza el refresh token). Aquí se hace lo que `iam` no puede:
/// llamar a `SignOut(sessionExpired)`, que da de baja el token push y limpia
/// cachés, estacionamiento elegido y estado de los stores.
///
/// **Salida para el router (fase 3):** este objeto es un [Listenable]. El
/// router lo recibe como `refreshListenable` y, en su `redirect`, manda a
/// `/login?reason=expired` mientras [hasExpired] sea `true`. [hasExpired] pasa a
/// `true` **después** de terminar la limpieza, así que cuando el router
/// redirige el dispositivo ya está limpio. Quien muestra el aviso en el login
/// llama a [acknowledge] (o el router al redirigir); un inicio de sesión
/// posterior también debe llamarlo, para que un login nuevo no vuelva a mostrar
/// el aviso.
class SessionExpiryCoordinator extends ChangeNotifier {
  SessionExpiryCoordinator({
    required this._watchExpiry,
    required this._signOut,
  });

  final WatchSessionExpiry _watchExpiry;
  final SignOut _signOut;

  StreamSubscription<SessionExpired>? _subscription;
  bool _hasExpired = false;
  bool _disposed = false;

  /// `true` desde que la sesión expiró y se limpió el dispositivo, hasta que
  /// alguien llama a [acknowledge].
  bool get hasExpired => _hasExpired;

  /// Empieza a escuchar. Llamarlo otra vez no hace nada.
  void start() {
    _subscription ??= _watchExpiry().listen((_) => unawaited(_onExpired()));
  }

  /// El aviso ya se mostró (o ya no hace falta): [hasExpired] vuelve a `false`.
  void acknowledge() {
    if (!_hasExpired) return;
    _hasExpired = false;
    notifyListeners();
  }

  Future<void> _onExpired() async {
    try {
      await _signOut(const SignOutParams(reason: SignOutReason.sessionExpired));
    } on Object {
      // `SignOut` no falla; aun así, el aviso al router no debe perderse.
    }
    if (_disposed) return;
    _hasExpired = true;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_subscription?.cancel());
    _subscription = null;
    super.dispose();
  }
}

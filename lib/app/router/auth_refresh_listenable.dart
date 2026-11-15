import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:quadrapp_mobile/contexts/iam/presentation/cubit/auth_cubit.dart';

/// Avisa al router cada vez que cambia el estado de sesión del [AuthCubit]
/// (`GoRouter.refreshListenable` solo entiende `Listenable`).
class AuthRefreshListenable extends ChangeNotifier {
  AuthRefreshListenable(AuthCubit cubit) {
    _subscription = cubit.stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<AuthState> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}

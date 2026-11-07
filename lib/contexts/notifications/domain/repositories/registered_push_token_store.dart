import 'package:quadrapp_mobile/contexts/notifications/domain/value_objects/push_token.dart';

/// El token que este dispositivo tiene registrado en el servidor. Persiste
/// para poder darlo de baja al cerrar sesión; es dato de usuario y se borra al
/// cerrar sesión (`Resettable`).
abstract interface class RegisteredPushTokenStore {
  Future<PushToken?> read();

  Future<void> save(PushToken token);

  Future<void> clear();
}

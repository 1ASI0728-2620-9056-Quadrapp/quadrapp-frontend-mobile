import 'package:quadrapp_mobile/contexts/notifications/domain/value_objects/push_token.dart';

/// El registro de "baja pendiente" del token push: el token que no se pudo
/// dar de baja en el servidor al cerrar sesión (sin red) y que se reintenta
/// después.
///
/// Guarda **solo el token del dispositivo**: ningún token de sesión, correo ni
/// dato del usuario. Por eso es el único dato (junto con el idioma) que
/// sobrevive a la limpieza del cierre de sesión.
abstract interface class PendingPushTokenRemovalStore {
  Future<PushToken?> read();

  Future<void> save(PushToken token);

  Future<void> clear();
}

import 'package:quadrapp_mobile/contexts/notifications/domain/entities/push_message.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/value_objects/push_permission_status.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/value_objects/push_token.dart';

/// El proveedor de mensajería push del dispositivo. Hoy solo existe el stub de
/// los mocks; `firebase_messaging` se integra en la fase 6.
///
/// Ninguna implementación pide el permiso por su cuenta: solo
/// [requestPermission], y lo llama el caso de uso de activación (docs/05
/// regla 11).
abstract interface class PushGateway {
  /// Estado actual del permiso, sin pedirlo.
  Future<PushPermissionStatus> permissionStatus();

  /// Muestra el diálogo del sistema (si todavía se puede) y devuelve el estado.
  Future<PushPermissionStatus> requestPermission();

  /// El token del dispositivo, o `null` si el proveedor no lo entrega.
  Future<PushToken?> token();

  /// Los mensajes que el conductor tocó. Ya vienen validados: un mensaje con
  /// tipo desconocido o sin estacionamiento no se emite.
  Stream<PushMessage> get openedMessages;
}

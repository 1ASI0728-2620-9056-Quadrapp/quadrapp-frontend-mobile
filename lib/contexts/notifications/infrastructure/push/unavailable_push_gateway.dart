import 'package:quadrapp_mobile/contexts/notifications/domain/entities/push_message.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/repositories/push_gateway.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/value_objects/push_permission_status.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/value_objects/push_token.dart';

/// `PushGateway` de la ejecución real mientras `firebase_messaging` no esté
/// integrado (fase 6): no hay proveedor de mensajería.
///
/// No hay token que registrar, así que `ActivateDeviceNotifications` termina en
/// `tokenUnavailable` sin llamar al servidor (y nunca se registra un token
/// falso). Se reemplaza por la implementación con Firebase en la fase 6, solo
/// en `app/di`.
class UnavailablePushGateway implements PushGateway {
  const UnavailablePushGateway();

  @override
  Future<PushPermissionStatus> permissionStatus() async =>
      PushPermissionStatus.granted;

  @override
  Future<PushPermissionStatus> requestPermission() async =>
      PushPermissionStatus.granted;

  @override
  Future<PushToken?> token() async => null;

  @override
  Stream<PushMessage> get openedMessages => const Stream.empty();
}

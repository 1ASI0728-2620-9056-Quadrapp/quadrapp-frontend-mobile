// US23
import 'package:quadrapp_mobile/contexts/notifications/domain/entities/push_message.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/repositories/push_gateway.dart';

/// Los mensajes push que el conductor toca. El router abre
/// `/lots/:lotId` con cada uno; no hay bandeja de alertas.
class WatchPushMessages {
  const WatchPushMessages(this._gateway);

  final PushGateway _gateway;

  Stream<PushMessage> call() => _gateway.openedMessages;
}

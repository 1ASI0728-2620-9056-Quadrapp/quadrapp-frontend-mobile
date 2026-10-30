import 'dart:async';

import 'package:quadrapp_mobile/app/mocks/mock_controls.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/entities/push_message.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/repositories/push_gateway.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/value_objects/push_permission_status.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/value_objects/push_token.dart';
import 'package:quadrapp_mobile/contexts/notifications/infrastructure/push/push_message_mapper.dart';
import 'package:quadrapp_mobile/core/logging/logger.dart';

/// `PushGateway` de los mocks: no usa Firebase (llega en la fase 6).
///
/// Se comporta como Android 13: el permiso empieza sin pedir (`denied`), se
/// concede al pedirlo y, con [MockControls.denyPushPermission], se niega; a la
/// segunda negativa pasa a `deniedForever` y ya no se puede pedir. Nunca pide
/// el permiso por su cuenta.
class StubPushGateway implements PushGateway {
  StubPushGateway(this._controls, Logger logger)
    : _mapper = PushMessageMapper(logger);

  /// Token fijo de los mocks. Lleva `:` a propósito, como los de FCM, para
  /// comprobar que se codifica en la URL.
  static const String mockToken = 'mock-fcm-token:APA91bQuadrapp';

  final MockControls _controls;
  final PushMessageMapper _mapper;
  final StreamController<PushMessage> _opened =
      StreamController<PushMessage>.broadcast();

  PushPermissionStatus _status = PushPermissionStatus.denied;
  int _denials = 0;

  @override
  Future<PushPermissionStatus> permissionStatus() async => _status;

  @override
  Future<PushPermissionStatus> requestPermission() async {
    if (_status != PushPermissionStatus.denied) return _status;
    if (_controls.denyPushPermission) {
      _denials++;
      _status = _denials >= 2
          ? PushPermissionStatus.deniedForever
          : PushPermissionStatus.denied;
    } else {
      _status = PushPermissionStatus.granted;
    }
    return _status;
  }

  @override
  Future<PushToken?> token() async => _controls.pushTokenUnavailable
      ? null
      : PushToken.create(mockToken).valueOrNull;

  @override
  Stream<PushMessage> get openedMessages => _opened.stream;

  /// Simula que el conductor toca una notificación con este `data` (para
  /// probar la navegación a `/lots/:lotId`). Un mensaje inválido se ignora,
  /// como en la implementación real.
  void simulateTap(Map<String, Object?> data) {
    final message = _mapper.fromData(data);
    if (message != null) _opened.add(message);
  }

  Future<void> dispose() => _opened.close();
}

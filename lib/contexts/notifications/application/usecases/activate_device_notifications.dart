// US33 (esc. 2), docs/05 regla 11
import 'package:quadrapp_mobile/contexts/notifications/domain/entities/device_activation.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/repositories/device_token_repository.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/repositories/pending_push_token_removal_store.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/repositories/push_gateway.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/repositories/registered_push_token_store.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/value_objects/push_permission_status.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/value_objects/push_token.dart';
import 'package:quadrapp_mobile/core/network/failure_mapper.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

/// Deja este dispositivo como destino de las alertas: permiso de
/// notificaciones, token y registro en el servidor.
///
/// Esta es la única regla de cuándo se pide el permiso (Android 13 o
/// superior): solo aquí, cuando el conductor se suscribe a una franja o activa
/// las notificaciones, con contexto; nunca al abrir la app. Si el sistema ya no
/// deja pedirlo, no se vuelve a intentar: se devuelve
/// [DeviceActivation.permissionBlocked] para que la pantalla lo explique.
///
/// Si el token que se registra es el mismo que quedó en la baja pendiente (otro
/// usuario inicia sesión en este teléfono), esa baja se descarta: el
/// `POST /device-tokens` ya lo reasignó, y reintentarla le borraría el registro
/// al usuario nuevo.
///
/// Una negativa del conductor no es un error: es un resultado
/// ([DeviceActivation]). Solo un fallo al registrar el token en el servidor
/// (por ejemplo, sin red) es `Err`.
class ActivateDeviceNotifications
    implements UseCase<DeviceActivation, NoParams> {
  const ActivateDeviceNotifications({
    required this._gateway,
    required this._devices,
    required this._tokenStore,
    required this._pendingRemovals,
  });

  final PushGateway _gateway;
  final DeviceTokenRepository _devices;
  final RegisteredPushTokenStore _tokenStore;
  final PendingPushTokenRemovalStore _pendingRemovals;

  @override
  Future<Result<DeviceActivation>> call(NoParams params) async {
    final _Resolved value;
    switch (await guardResult(_resolveToken)) {
      case Err(:final failure):
        return Err(failure);
      case Success(value: final resolved):
        value = resolved;
    }

    final token = value.token;
    if (token == null) return Success(value.activation);
    if (value.alreadyRegistered) {
      return const Success(DeviceActivation.registered);
    }

    final registered = await _devices.register(token);
    if (registered case Err(:final failure)) return Err(failure);
    final saved = await guardResult(() async {
      await _tokenStore.save(token);
      if (await _pendingRemovals.read() == token) {
        await _pendingRemovals.clear();
      }
    });
    if (saved case Err(:final failure)) return Err(failure);
    return const Success(DeviceActivation.registered);
  }

  Future<_Resolved> _resolveToken() async {
    var status = await _gateway.permissionStatus();
    if (status == PushPermissionStatus.denied) {
      status = await _gateway.requestPermission();
    }
    switch (status) {
      case PushPermissionStatus.denied:
        return const _Resolved(DeviceActivation.permissionDenied);
      case PushPermissionStatus.deniedForever:
        return const _Resolved(DeviceActivation.permissionBlocked);
      case PushPermissionStatus.granted:
        break;
    }
    final token = await _gateway.token();
    if (token == null) {
      return const _Resolved(DeviceActivation.tokenUnavailable);
    }
    final stored = await _tokenStore.read();
    return _Resolved(
      DeviceActivation.registered,
      token: token,
      alreadyRegistered: stored == token,
    );
  }
}

class _Resolved {
  const _Resolved(
    this.activation, {
    this.token,
    this.alreadyRegistered = false,
  });

  final DeviceActivation activation;
  final PushToken? token;
  final bool alreadyRegistered;
}

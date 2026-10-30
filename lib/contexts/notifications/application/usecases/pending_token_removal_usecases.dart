// US02 (esc. 3), TS12
import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/notifications/application/usecases/device_token_usecases.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/entities/device_token_removal.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/repositories/device_token_repository.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/repositories/pending_push_token_removal_store.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/value_objects/push_token.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/network/failure_mapper.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

/// Un fallo que puede arreglarse esperando: sin red, error del servidor o
/// demasiadas solicitudes. Cualquier otro (p. ej. un 400) no se arregla
/// reintentando.
bool _isRetryable(Failure failure) =>
    failure is NetworkFailure ||
    failure is ServerFailure ||
    failure is RateLimitedFailure;

class RemoveDeviceTokenOnSignOutParams extends Equatable {
  const RemoveDeviceTokenOnSignOutParams({this.token});

  /// El token que `composition/sign_out` leyó **antes** de limpiar los
  /// almacenes. Sin token no hay nada que dar de baja.
  final PushToken? token;

  @override
  List<Object?> get props => [token];
}

/// Da de baja el token push al cerrar sesión. Si el servidor no responde (sin
/// red, 5xx, 429), guarda ese token en la baja pendiente para reintentar
/// después (`RetryPendingTokenRemoval`); nunca falla el cierre de sesión.
class RemoveDeviceTokenOnSignOut
    implements UseCase<DeviceTokenRemoval, RemoveDeviceTokenOnSignOutParams> {
  const RemoveDeviceTokenOnSignOut({
    required this._unregister,
    required this._pendingRemovals,
  });

  final UnregisterDeviceToken _unregister;
  final PendingPushTokenRemovalStore _pendingRemovals;

  @override
  Future<Result<DeviceTokenRemoval>> call(
    RemoveDeviceTokenOnSignOutParams params,
  ) async {
    final token = params.token;
    if (token == null) return const Success(DeviceTokenRemoval.nothingToRemove);

    switch (await _unregister(UnregisterDeviceTokenParams(token: token))) {
      case Success():
        return const Success(DeviceTokenRemoval.removed);
      case Err(:final failure) when _isRetryable(failure):
        final saved = await guardResult(() => _pendingRemovals.save(token));
        return saved.map((_) => DeviceTokenRemoval.pending);
      case Err():
        return const Success(DeviceTokenRemoval.abandoned);
    }
  }
}

/// Reintenta la baja pendiente del token push. Se llama al arrancar la app y
/// cada vez que vuelve a primer plano; no necesita sesión (la ruta es
/// pública). El registro se borra al lograrlo (o ante un 404); se conserva ante
/// un fallo de red o un 5xx.
class RetryPendingTokenRemoval
    implements UseCase<DeviceTokenRemoval, NoParams> {
  const RetryPendingTokenRemoval({
    required this._devices,
    required this._pendingRemovals,
  });

  final DeviceTokenRepository _devices;
  final PendingPushTokenRemovalStore _pendingRemovals;

  @override
  Future<Result<DeviceTokenRemoval>> call(NoParams params) async {
    final PushToken? token;
    switch (await guardResult(_pendingRemovals.read)) {
      case Err(:final failure):
        return Err(failure);
      case Success(value: final pending):
        token = pending;
    }
    if (token == null) return const Success(DeviceTokenRemoval.nothingToRemove);

    switch (await _devices.unregister(token)) {
      case Success():
        return (await guardResult(
          _pendingRemovals.clear,
        )).map((_) => DeviceTokenRemoval.removed);
      case Err(:final failure) when _isRetryable(failure):
        return const Success(DeviceTokenRemoval.pending);
      case Err():
        return (await guardResult(
          _pendingRemovals.clear,
        )).map((_) => DeviceTokenRemoval.abandoned);
    }
  }
}

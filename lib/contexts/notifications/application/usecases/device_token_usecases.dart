// US02 (esc. 3), TS12
import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/repositories/device_token_repository.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/repositories/registered_push_token_store.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/value_objects/push_token.dart';
import 'package:quadrapp_mobile/core/network/failure_mapper.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

/// El token que este dispositivo tiene registrado en el servidor, o `null`.
/// Lo usa `composition/sign_out` para guardarlo y reintentar la baja si no hay
/// red.
class GetRegisteredPushToken implements UseCase<PushToken?, NoParams> {
  const GetRegisteredPushToken(this._tokenStore);

  final RegisteredPushTokenStore _tokenStore;

  @override
  Future<Result<PushToken?>> call(NoParams params) =>
      guardResult(_tokenStore.read);
}

class UnregisterDeviceTokenParams extends Equatable {
  /// Sin [token], se da de baja el que está registrado en este dispositivo.
  const UnregisterDeviceTokenParams({this.token});

  final PushToken? token;

  @override
  List<Object?> get props => [token];
}

/// Da de baja el token del dispositivo en el servidor
/// (`POST /device-tokens/unregister`, 404 cuenta como éxito) para que el
/// siguiente usuario del teléfono no reciba las alertas del anterior. Lo usa
/// `composition/sign_out` antes de cerrar la sesión.
///
/// Si la baja falla (sin red), el token guardado se conserva para poder
/// reintentar; solo se borra al lograrla. Sin token registrado no hace nada.
class UnregisterDeviceToken
    implements UseCase<void, UnregisterDeviceTokenParams> {
  const UnregisterDeviceToken({
    required this._devices,
    required this._tokenStore,
  });

  final DeviceTokenRepository _devices;
  final RegisteredPushTokenStore _tokenStore;

  @override
  Future<Result<void>> call(UnregisterDeviceTokenParams params) async {
    final PushToken? token;
    switch (await guardResult(
      () async => params.token ?? await _tokenStore.read(),
    )) {
      case Err(:final failure):
        return Err(failure);
      case Success(value: final found):
        token = found;
    }
    if (token == null) return const Success<void>(null);

    if (await _devices.unregister(token) case Err(:final failure)) {
      return Err(failure);
    }
    return guardResult(() async {
      if (await _tokenStore.read() == token) await _tokenStore.clear();
    });
  }
}

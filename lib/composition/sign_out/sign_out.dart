// US02, US03
import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/iam/iam.dart';
import 'package:quadrapp_mobile/contexts/notifications/notifications.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/session/resettable.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

/// Por qué se cierra la sesión.
enum SignOutReason {
  /// El usuario pidió cerrar sesión (US02).
  userRequested,

  /// La sesión expiró (US03): el servidor ya rechazó el refresh token, así que
  /// no se llama a `POST /auth/logout`.
  sessionExpired,
}

class SignOutParams extends Equatable {
  const SignOutParams({this.reason = SignOutReason.userRequested});

  final SignOutReason reason;

  @override
  List<Object?> get props => [reason];
}

/// Qué pasó con lo que depende del servidor. La limpieza local siempre ocurre.
class SignOutReport extends Equatable {
  const SignOutReport({required this.pushToken, required this.sessionRevoked});

  /// La baja del token push (US02 esc. 3).
  final DeviceTokenRemoval pushToken;

  /// `true` si el servidor revocó la sesión (o ya no era válida). `false` si
  /// no se pudo (sin red) o si no hacía falta (sesión expirada).
  final bool sessionRevoked;

  @override
  List<Object?> get props => [pushToken, sessionRevoked];
}

/// Cierra la sesión (US02) combinando `iam` y `notifications`.
///
/// En este orden:
/// 1. Lee el token push registrado **antes** de limpiar ningún almacén.
/// 2. Da de baja ese token en el servidor (`POST /device-tokens/unregister`).
///    Sin red, 5xx o 429, lo deja como baja pendiente (`device.`, sobrevive a
///    la limpieza) y se reintenta al arrancar y al volver a primer plano.
/// 3. Revoca la sesión (`POST /auth/logout`, de mejor esfuerzo; se omite si la
///    sesión ya expiró).
/// 4. Limpia en el dispositivo: tokens, todas las cachés, el estacionamiento
///    elegido y el estado de los stores (`ResettableRegistry`). Se conservan
///    **solo** el idioma y la baja pendiente del token push.
///
/// Nunca falla: sin red, limpia en local igual (el refresh token no se
/// conserva; la revocación en el servidor es de mejor esfuerzo).
///
/// **Un solo cierre a la vez:** si se llama mientras otro está en curso (por
/// ejemplo, la sesión expira durante el `POST /auth/logout` de un cierre pedido
/// por el usuario), comparte ese mismo cierre en lugar de repetir los pasos (no
/// se da de baja el token push dos veces).
class SignOut implements UseCase<SignOutReport, SignOutParams> {
  SignOut({
    required this._getPushToken,
    required this._removePushToken,
    required this._revokeSession,
    required this._clearSession,
    required this._resettables,
  });

  final GetRegisteredPushToken _getPushToken;
  final RemoveDeviceTokenOnSignOut _removePushToken;
  final RevokeSession _revokeSession;
  final ClearSession _clearSession;
  final ResettableRegistry _resettables;

  Future<Result<SignOutReport>>? _inFlight;

  @override
  Future<Result<SignOutReport>> call(SignOutParams params) =>
      _inFlight ??= _signOut(params).whenComplete(() => _inFlight = null);

  Future<Result<SignOutReport>> _signOut(SignOutParams params) async {
    var pushToken = DeviceTokenRemoval.nothingToRemove;
    var sessionRevoked = false;
    try {
      final token = (await _getPushToken(const NoParams())).valueOrNull;
      pushToken =
          (await _removePushToken(
            RemoveDeviceTokenOnSignOutParams(token: token),
          )).valueOrNull ??
          (token == null
              ? DeviceTokenRemoval.nothingToRemove
              : DeviceTokenRemoval.abandoned);

      if (params.reason == SignOutReason.userRequested) {
        sessionRevoked = (await _revokeSession(const NoParams())).isSuccess;
      }
    } finally {
      // Pase lo que pase arriba, el dispositivo queda limpio (US02 esc. 3).
      await _clearSession(const NoParams());
      await _resettables.resetAll();
    }
    return Success(
      SignOutReport(pushToken: pushToken, sessionRevoked: sessionRevoked),
    );
  }
}

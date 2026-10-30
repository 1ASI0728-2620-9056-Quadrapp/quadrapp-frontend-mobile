import 'package:quadrapp_mobile/contexts/notifications/domain/value_objects/push_token.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// Los dispositivos del conductor que reciben alertas, en el servidor
/// (`/device-tokens`).
abstract interface class DeviceTokenRepository {
  /// Registra el token de este dispositivo. Repetirlo no falla.
  Future<Result<void>> register(PushToken token);

  /// Da de baja el token para que nadie más reciba las alertas en este
  /// dispositivo. Que ya no exista cuenta como éxito.
  Future<Result<void>> unregister(PushToken token);
}

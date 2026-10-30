import 'package:quadrapp_mobile/contexts/parking_sensing/domain/entities/device.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/domain/entities/new_device.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// Alta y baja de dispositivos (US32 esc. 1 y 3).
abstract interface class DeviceRegistry {
  /// Registra [device]; queda operativo y sin espacio ni acceso asociado.
  /// `ValidationFailure` con `hardwareId` si el identificador ya existe (409)
  /// o con el campo inválido (400).
  Future<Result<Device>> register(NewDevice device);

  /// Da de baja un dispositivo: deja de aceptar eventos y queda en el
  /// inventario como historial. Un dispositivo que ya no existe cuenta como
  /// éxito (el objetivo ya se cumplió).
  Future<Result<void>> decommission(DeviceId id);
}

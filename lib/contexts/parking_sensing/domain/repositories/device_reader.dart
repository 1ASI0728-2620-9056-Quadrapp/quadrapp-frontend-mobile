import 'package:quadrapp_mobile/contexts/parking_sensing/domain/entities/device_inventory.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// Lectura de la salud del inventario de un estacionamiento (US20, TS10).
// ignore: one_member_abstracts
abstract interface class DeviceReader {
  /// Los dispositivos del estacionamiento con su estado, batería y última
  /// comunicación. `ForbiddenFailure` si la sesión no es de Operación (403).
  Future<Result<DeviceInventory>> read(LotId lotId);
}

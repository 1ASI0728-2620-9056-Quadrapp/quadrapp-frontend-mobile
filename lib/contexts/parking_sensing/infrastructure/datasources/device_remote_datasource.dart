import 'package:quadrapp_mobile/contexts/parking_sensing/infrastructure/dto/device_dtos.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

/// Origen remoto del inventario de dispositivos (HTTP o mock).
abstract interface class DeviceRemoteDataSource {
  /// `GET /devices/health?lotId=`.
  Future<DeviceHealthDto> health(LotId lotId);

  /// `POST /devices`.
  Future<DeviceDto> register(RegisterDeviceRequestDto request);

  /// `DELETE /devices/{id}`.
  Future<void> decommission(DeviceId id);
}

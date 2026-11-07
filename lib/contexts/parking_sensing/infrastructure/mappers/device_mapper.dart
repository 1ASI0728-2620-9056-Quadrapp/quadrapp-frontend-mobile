import 'package:quadrapp_mobile/contexts/parking_sensing/domain/entities/device.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/domain/entities/device_inventory.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/domain/entities/new_device.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/domain/value_objects/device_status.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/domain/value_objects/device_type.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/infrastructure/dto/device_dtos.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/logging/logger.dart';
import 'package:quadrapp_mobile/core/network/parse_exception.dart';

/// DTO <-> entidades del dominio. Un valor desconocido del servidor no rompe
/// la pantalla:
/// - un `status` que la app no reconoce se trata como `UNREACHABLE` (el lado
///   cauteloso: no se muestra como operativo) y deja un aviso;
/// - un dispositivo de un `type` desconocido se omite de la lista (no se puede
///   mostrar sin saber qué es) y deja un aviso.
class DeviceMapper {
  const DeviceMapper(this._logger);

  final Logger _logger;

  /// [receivedAt] es la lectura del reloj monótono al recibir la respuesta.
  DeviceInventory toInventory(
    DeviceHealthDto dto,
    LotId lotId, {
    required Duration receivedAt,
  }) {
    final devices = <Device>[];
    for (final item in dto.devices) {
      final device = _toDeviceOrNull(item, lotId);
      if (device != null) devices.add(device);
    }
    return DeviceInventory(
      lotId: lotId,
      devices: devices,
      serverTime: dto.serverTime.toUtc(),
      receivedAt: receivedAt,
    );
  }

  /// La respuesta de `POST /devices`. Un tipo ilegible es una respuesta
  /// ilegible (`ParseFailure`).
  Device toDevice(DeviceDto dto, LotId lotId) =>
      _toDeviceOrNull(dto, lotId) ??
      (throw const ParseException('El tipo del dispositivo no es válido.'));

  Device? _toDeviceOrNull(DeviceDto dto, LotId lotId) {
    final type = parseType(dto.type);
    if (type == null) {
      _logger.warning(
        'Tipo de dispositivo no reconocido "${dto.type}": se omite',
      );
      return null;
    }
    return Device(
      id: DeviceId(dto.id),
      lotId: lotId,
      hardwareId: dto.hardwareId,
      type: type,
      status: parseStatus(dto.status),
      expectedReportInterval: Duration(seconds: dto.expectedReportIntervalSec),
      batteryPct: dto.batteryPct,
      lastSeenAt: dto.lastSeenAt?.toUtc(),
      directional: dto.directional,
      spaceLabel: dto.spaceLabel,
    );
  }

  RegisterDeviceRequestDto toRequest(NewDevice device) =>
      RegisterDeviceRequestDto(
        lotId: device.lotId.value,
        type: typeToApi(device.type),
        hardwareId: device.hardwareId,
        expectedReportIntervalSec: device.expectedReportInterval.inSeconds,
        directional: device.directional,
      );

  /// `SPACE_SENSOR`, `PASS_SENSOR` y `GATEWAY`, sin distinguir mayúsculas; otro
  /// valor es `null`.
  DeviceType? parseType(String raw) => switch (raw.toUpperCase()) {
    'SPACE_SENSOR' => DeviceType.spaceSensor,
    'PASS_SENSOR' => DeviceType.passSensor,
    'GATEWAY' => DeviceType.gateway,
    _ => null,
  };

  String typeToApi(DeviceType type) => switch (type) {
    DeviceType.spaceSensor => 'SPACE_SENSOR',
    DeviceType.passSensor => 'PASS_SENSOR',
    DeviceType.gateway => 'GATEWAY',
  };

  /// `OPERATIONAL`, `UNREACHABLE`, `LOW_BATTERY` y `DECOMMISSIONED`, sin
  /// distinguir mayúsculas. Cualquier otro valor es `UNREACHABLE`.
  DeviceStatus parseStatus(String raw) {
    switch (raw.toUpperCase()) {
      case 'OPERATIONAL':
        return DeviceStatus.operational;
      case 'UNREACHABLE':
        return DeviceStatus.unreachable;
      case 'LOW_BATTERY':
        return DeviceStatus.lowBattery;
      case 'DECOMMISSIONED':
        return DeviceStatus.decommissioned;
    }
    _logger.warning('Estado de dispositivo no reconocido "$raw": UNREACHABLE');
    return DeviceStatus.unreachable;
  }
}

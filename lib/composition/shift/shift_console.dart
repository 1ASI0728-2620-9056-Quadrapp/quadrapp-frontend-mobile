// US29, TS17, US20
import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/composition/shift/shift_overview.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/parking_sensing.dart';

/// Lo que muestra la consola de turno: el estado de operación del
/// estacionamiento ([overview]) y, si se pudo leer, la salud de sus
/// dispositivos ([devices]) para el bloque «Alertas».
///
/// Es estado de presentación, no una entidad: combina dos lecturas que ya
/// existen (`GET /console/overview` y `GET /devices/health`).
class ShiftConsole extends Equatable {
  const ShiftConsole({required this.overview, this.devices});

  final ShiftOverview overview;

  /// `null` si el inventario no se pudo leer (la consola sigue, en parcial).
  final DeviceInventory? devices;

  bool get devicesUnavailable => devices == null;

  /// La consola llegó incompleta: le falta el pronóstico, el flujo o los
  /// dispositivos.
  bool get isPartial => overview.unavailable.isNotEmpty || devicesUnavailable;

  /// Las incidencias de dispositivos que piden atención durante el turno.
  ShiftDeviceAlerts get alerts => ShiftDeviceAlerts.from(devices);

  @override
  List<Object?> get props => [overview, devices];
}

/// Resumen de las incidencias de dispositivos para la consola: cada gateway
/// sin comunicación por separado (deja sin datos a todos sus sensores) y los
/// sensores agrupados por motivo. Los dados de baja no cuentan.
class ShiftDeviceAlerts extends Equatable {
  const ShiftDeviceAlerts({
    this.unreachableGateways = const [],
    this.unreachableSensors = 0,
    this.lowBatterySensors = 0,
  });

  factory ShiftDeviceAlerts.from(DeviceInventory? inventory) {
    if (inventory == null) return const ShiftDeviceAlerts();
    final gateways = <Device>[];
    var unreachable = 0;
    var lowBattery = 0;
    for (final device in inventory.devices) {
      if (device.isDecommissioned) continue;
      final isGateway = device.type == DeviceType.gateway;
      switch (device.status) {
        case DeviceStatus.unreachable when isGateway:
          gateways.add(device);
        case DeviceStatus.unreachable:
          unreachable++;
        case DeviceStatus.lowBattery:
          lowBattery++;
        case DeviceStatus.operational:
        case DeviceStatus.decommissioned:
          break;
      }
    }
    return ShiftDeviceAlerts(
      unreachableGateways: gateways,
      unreachableSensors: unreachable,
      lowBatterySensors: lowBattery,
    );
  }

  final List<Device> unreachableGateways;
  final int unreachableSensors;
  final int lowBatterySensors;

  bool get isEmpty =>
      unreachableGateways.isEmpty &&
      unreachableSensors == 0 &&
      lowBatterySensors == 0;

  @override
  List<Object?> get props => [
    unreachableGateways,
    unreachableSensors,
    lowBatterySensors,
  ];
}

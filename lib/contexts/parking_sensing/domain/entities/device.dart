import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/domain/value_objects/device_status.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/domain/value_objects/device_type.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

/// Un sensor o gateway del inventario de un estacionamiento (US20, US32,
/// TS10). La app de Operación lo lee y puede registrarlo o darlo de baja;
/// asignarlo a un espacio o acceso y reemplazarlo es de la consola web.
class Device extends Equatable {
  const Device({
    required this.id,
    required this.lotId,
    required this.hardwareId,
    required this.type,
    required this.status,
    required this.expectedReportInterval,
    this.batteryPct,
    this.lastSeenAt,
    this.directional,
    this.spaceLabel,
  });

  final DeviceId id;
  final LotId lotId;

  /// El identificador físico (único en la institución).
  final String hardwareId;
  final DeviceType type;
  final DeviceStatus status;

  /// Cada cuánto debe reportar; si pasa más tiempo sin hacerlo, queda sin
  /// comunicación.
  final Duration expectedReportInterval;

  /// 0 a 100; `null` si el dispositivo no informa batería (un gateway
  /// conectado a la red).
  final int? batteryPct;

  /// Su última comunicación (UTC); `null` si nunca reportó.
  final DateTime? lastSeenAt;

  /// Solo en un sensor de paso: si distingue entradas de salidas.
  final bool? directional;

  /// La etiqueta del espacio al que está asociado, si lo está.
  final String? spaceLabel;

  bool get isOperational => status == DeviceStatus.operational;
  bool get isDecommissioned => status == DeviceStatus.decommissioned;

  /// Pide atención de quien opera: sin comunicación o con batería baja.
  bool get needsAttention =>
      status == DeviceStatus.unreachable || status == DeviceStatus.lowBattery;

  @override
  List<Object?> get props => [
    id.value,
    lotId.value,
    hardwareId,
    type,
    status,
    expectedReportInterval,
    batteryPct,
    lastSeenAt,
    directional,
    spaceLabel,
  ];
}

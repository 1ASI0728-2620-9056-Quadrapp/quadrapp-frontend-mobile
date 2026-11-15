import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/domain/entities/device.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/domain/value_objects/device_status.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';

/// El inventario de dispositivos de un estacionamiento, con la hora del
/// servidor a la que se leyó (US20, TS10).
///
/// La antigüedad de la última comunicación de un dispositivo se calcula como
/// en la ocupación: `serverTime − lastSeenAt` más el tiempo transcurrido
/// localmente desde que llegó la respuesta (reloj monótono), nunca con el
/// reloj del teléfono.
class DeviceInventory extends Equatable {
  const DeviceInventory({
    required this.lotId,
    required this.devices,
    required this.serverTime,
    required this.receivedAt,
  });

  final LotId lotId;
  final List<Device> devices;

  /// Hora del servidor al armar la respuesta (UTC).
  final DateTime serverTime;

  /// Lectura del reloj monótono al recibir la respuesta.
  final Duration receivedAt;

  /// Cuántos dispositivos hay en el estado [status].
  int countOf(DeviceStatus status) =>
      devices.where((device) => device.status == status).length;

  /// Cuántos piden atención (sin comunicación o con batería baja).
  int get attentionCount => devices.where((d) => d.needsAttention).length;

  /// Los dispositivos que cumplen el filtro por estado ([status], si se da) y
  /// el buscador ([query], sin distinguir mayúsculas, contra el identificador
  /// físico y la etiqueta del espacio).
  List<Device> where({DeviceStatus? status, String query = ''}) {
    final needle = query.trim().toLowerCase();
    return [
      for (final device in devices)
        if ((status == null || device.status == status) &&
            (needle.isEmpty ||
                device.hardwareId.toLowerCase().contains(needle) ||
                (device.spaceLabel?.toLowerCase().contains(needle) ?? false)))
          device,
    ];
  }

  /// Hace cuánto fue la última comunicación de [device], o `null` si nunca
  /// reportó.
  Duration? lastSeenAge(Device device, Clock clock) {
    final seen = device.lastSeenAt;
    if (seen == null) return null;
    final atServer = _nonNegative(serverTime.difference(seen));
    final local = _nonNegative(clock.monotonic() - receivedAt);
    return atServer + local;
  }

  static Duration _nonNegative(Duration value) =>
      value.isNegative ? Duration.zero : value;

  @override
  List<Object?> get props => [lotId.value, devices, serverTime, receivedAt];
}

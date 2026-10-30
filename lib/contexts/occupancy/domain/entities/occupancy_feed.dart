// US07, TS09
import 'package:quadrapp_mobile/contexts/occupancy/domain/entities/lot_occupancy.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// Estado **real** de la conexión en tiempo real de un estacionamiento. Es lo
/// que muestra el chip "Live": nunca es decorativo.
enum RealtimeLink {
  /// Todavía no se estableció la primera conexión.
  connecting,

  /// Conectado y recibiendo cambios.
  live,

  /// Se perdió la conexión; se reintenta sola con espera exponencial.
  reconnecting,
}

/// Lo que emite el seguimiento de un estacionamiento: una ocupación (o el
/// fallo de leerla) y cada cambio del estado de la conexión.
sealed class OccupancyFeedEvent {
  const OccupancyFeedEvent();
}

/// Llegó una ocupación: el estado completo o el resultado de aplicar un
/// cambio.
final class OccupancyReceived extends OccupancyFeedEvent {
  const OccupancyReceived(this.result);

  final Result<LotOccupancy> result;
}

/// Cambió el estado de la conexión. Solo se emite cuando es distinto del
/// anterior.
final class LinkChanged extends OccupancyFeedEvent {
  const LinkChanged(this.link);

  final RealtimeLink link;
}

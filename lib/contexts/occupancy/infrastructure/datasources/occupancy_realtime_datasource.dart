import 'package:quadrapp_mobile/contexts/occupancy/infrastructure/dto/space_change_dto.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

/// Evento de la conexión en tiempo real.
sealed class OccupancyRealtimeEvent {
  const OccupancyRealtimeEvent();
}

/// La conexión quedó establecida (también tras cada reconexión).
final class RealtimeConnected extends OccupancyRealtimeEvent {
  const RealtimeConnected();
}

/// Llegó un cambio de estado de un espacio.
final class RealtimeChange extends OccupancyRealtimeEvent {
  const RealtimeChange(this.change);

  final SpaceChangeDto change;
}

/// Se perdió la conexión (se reintenta sola).
final class RealtimeDisconnected extends OccupancyRealtimeEvent {
  const RealtimeDisconnected();
}

/// Origen en tiempo real de los cambios de ocupación.
// ignore: one_member_abstracts
abstract interface class OccupancyRealtimeDataSource {
  /// Abre la conexión al suscribirse; cancelar la suscripción la cierra. Se
  /// reconecta con espera exponencial y tope.
  Stream<OccupancyRealtimeEvent> connect(LotId lotId);
}

import 'package:quadrapp_mobile/contexts/occupancy/domain/entities/lot_occupancy.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/entities/occupancy_feed.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// Ocupación en tiempo casi real (US07, TS09).
abstract interface class OccupancyRealtime {
  /// Emite primero el estado completo y luego una ocupación nueva por cada
  /// cambio aplicado. Se reconecta sola y, al reconectar, vuelve a pedir el
  /// estado completo. Cancelar la suscripción cierra la conexión.
  Stream<Result<LotOccupancy>> watch(LotId lotId);

  /// Lo mismo que [watch], más el estado real de la conexión: emite
  /// [RealtimeLink.connecting] al empezar, [RealtimeLink.live] al conectar y
  /// [RealtimeLink.reconnecting] al perderla. Comparte la misma conexión y las
  /// mismas reglas (idempotencia y orden); [watch] es solo sus ocupaciones.
  Stream<OccupancyFeedEvent> feed(LotId lotId);
}

// US07, TS09
import 'package:quadrapp_mobile/contexts/occupancy/domain/entities/occupancy_feed.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/repositories/occupancy_realtime.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

/// Observa un estacionamiento en tiempo casi real **con el estado real de la
/// conexión**: las ocupaciones y, aparte, si el enlace está vivo, conectando o
/// reconectando (el chip "Live" de Inicio).
class WatchLotFeed {
  const WatchLotFeed(this._realtime);

  final OccupancyRealtime _realtime;

  Stream<OccupancyFeedEvent> call(LotId lotId) => _realtime.feed(lotId);
}

// US07, TS09
import 'package:quadrapp_mobile/contexts/occupancy/domain/entities/lot_occupancy.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/repositories/occupancy_realtime.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// Observa la ocupación en tiempo casi real: el estado completo y luego cada
/// cambio.
class WatchLotOccupancy {
  const WatchLotOccupancy(this._realtime);

  final OccupancyRealtime _realtime;

  Stream<Result<LotOccupancy>> call(LotId lotId) => _realtime.watch(lotId);
}

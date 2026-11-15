// US21, TS11
import 'package:quadrapp_mobile/contexts/analytics/domain/entities/occupancy_history.dart';
import 'package:quadrapp_mobile/contexts/analytics/domain/repositories/analytics_reader.dart';
import 'package:quadrapp_mobile/contexts/analytics/domain/value_objects/analytics_period.dart';
import 'package:quadrapp_mobile/contexts/analytics/domain/value_objects/occupancy_granularity.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

/// Qué historial pedir: el estacionamiento, el rango y, si se filtra, la zona
/// (US21 esc. 2).
typedef OccupancyHistoryQuery = ({
  LotId lotId,
  AnalyticsRange range,
  ZoneId? zoneId,
});

/// El historial de ocupación del rango, por hora si cabe en un día y por día
/// si no (TS11 esc. 1). Sin registros, el historial llega vacío (US21
/// esc. 3).
class GetOccupancyHistory
    implements UseCase<OccupancyHistory, OccupancyHistoryQuery> {
  const GetOccupancyHistory(this._reader);

  final AnalyticsReader _reader;

  @override
  Future<Result<OccupancyHistory>> call(OccupancyHistoryQuery query) =>
      _reader.occupancy(
        lotId: query.lotId,
        range: query.range,
        zoneId: query.zoneId,
        granularity: OccupancyGranularity.forLength(query.range.length),
      );
}

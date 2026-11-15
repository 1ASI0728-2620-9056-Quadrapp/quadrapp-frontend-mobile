// US22
import 'package:quadrapp_mobile/contexts/analytics/domain/entities/peak_hours.dart';
import 'package:quadrapp_mobile/contexts/analytics/domain/repositories/analytics_reader.dart';
import 'package:quadrapp_mobile/contexts/analytics/domain/value_objects/analytics_period.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

/// Un estacionamiento y un rango.
typedef LotRangeQuery = ({LotId lotId, AnalyticsRange range});

/// Las horas de mayor ocupación del rango; sin historial suficiente, lo dice
/// (US22 esc. 3).
class GetPeakHours implements UseCase<PeakHours, LotRangeQuery> {
  const GetPeakHours(this._reader);

  final AnalyticsReader _reader;

  @override
  Future<Result<PeakHours>> call(LotRangeQuery query) =>
      _reader.peaks(lotId: query.lotId, range: query.range);
}

// US34, TS11
import 'package:quadrapp_mobile/contexts/analytics/application/usecases/get_peak_hours.dart';
import 'package:quadrapp_mobile/contexts/analytics/domain/entities/forecast_accuracy.dart';
import 'package:quadrapp_mobile/contexts/analytics/domain/repositories/analytics_reader.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

/// El error absoluto medio y el porcentaje dentro del margen de cada versión
/// del modelo y horizonte en el rango (US34 esc. 1 y 2). Un periodo sin
/// pronósticos u ocupación suficientes llega como no calculable (esc. 3).
class GetForecastAccuracy implements UseCase<ForecastAccuracy, LotRangeQuery> {
  const GetForecastAccuracy(this._reader);

  final AnalyticsReader _reader;

  @override
  Future<Result<ForecastAccuracy>> call(LotRangeQuery query) =>
      _reader.accuracy(lotId: query.lotId, range: query.range);
}

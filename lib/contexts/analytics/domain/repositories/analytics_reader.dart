import 'package:quadrapp_mobile/contexts/analytics/domain/entities/forecast_accuracy.dart';
import 'package:quadrapp_mobile/contexts/analytics/domain/entities/occupancy_history.dart';
import 'package:quadrapp_mobile/contexts/analytics/domain/entities/peak_hours.dart';
import 'package:quadrapp_mobile/contexts/analytics/domain/value_objects/analytics_period.dart';
import 'package:quadrapp_mobile/contexts/analytics/domain/value_objects/occupancy_granularity.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// Consultas históricas del contexto Analytics (US21, US22, US34, TS11).
/// Todas responden `ForbiddenFailure` a un conductor (403) y
/// `ValidationFailure` a un rango inválido (400).
abstract interface class AnalyticsReader {
  /// `GET /analytics/occupancy`.
  Future<Result<OccupancyHistory>> occupancy({
    required LotId lotId,
    required AnalyticsRange range,
    required OccupancyGranularity granularity,
    ZoneId? zoneId,
  });

  /// `GET /analytics/peaks`.
  Future<Result<PeakHours>> peaks({
    required LotId lotId,
    required AnalyticsRange range,
  });

  /// `GET /analytics/accuracy`.
  Future<Result<ForecastAccuracy>> accuracy({
    required LotId lotId,
    required AnalyticsRange range,
  });
}

import 'package:quadrapp_mobile/contexts/analytics/infrastructure/dto/analytics_dtos.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

/// Origen remoto de la analítica (HTTP o mock). Las fechas viajan en UTC.
abstract interface class AnalyticsRemoteDataSource {
  /// `GET /analytics/occupancy`. [granularity] es `HOUR` o `DAY`.
  Future<OccupancyHistoryDto> occupancy({
    required LotId lotId,
    required DateTime from,
    required DateTime to,
    required String granularity,
    ZoneId? zoneId,
  });

  /// `GET /analytics/peaks`.
  Future<PeakHoursDto> peaks({
    required LotId lotId,
    required DateTime from,
    required DateTime to,
  });

  /// `GET /analytics/accuracy`.
  Future<List<AccuracyResultDto>> accuracy({
    required LotId lotId,
    required DateTime from,
    required DateTime to,
  });

  /// `POST /analytics/reports`.
  Future<ReportDeliveryDto> exportReport(ReportRequestDto request);
}

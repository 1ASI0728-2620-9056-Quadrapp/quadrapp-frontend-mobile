import 'package:quadrapp_mobile/contexts/analytics/domain/entities/analytics_report.dart';
import 'package:quadrapp_mobile/contexts/analytics/domain/entities/forecast_accuracy.dart';
import 'package:quadrapp_mobile/contexts/analytics/domain/entities/occupancy_history.dart';
import 'package:quadrapp_mobile/contexts/analytics/domain/entities/peak_hours.dart';
import 'package:quadrapp_mobile/contexts/analytics/domain/repositories/analytics_reader.dart';
import 'package:quadrapp_mobile/contexts/analytics/domain/repositories/report_exporter.dart';
import 'package:quadrapp_mobile/contexts/analytics/domain/value_objects/analytics_period.dart';
import 'package:quadrapp_mobile/contexts/analytics/domain/value_objects/occupancy_granularity.dart';
import 'package:quadrapp_mobile/contexts/analytics/infrastructure/datasources/analytics_remote_datasource.dart';
import 'package:quadrapp_mobile/contexts/analytics/infrastructure/mappers/analytics_mapper.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/network/failure_mapper.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// Lee la analítica y convierte cualquier falla de infraestructura en una
/// `Failure`. Sin caché: son consultas de un periodo que se piden al abrir la
/// pantalla o al cambiar el filtro.
class AnalyticsReaderImpl implements AnalyticsReader {
  const AnalyticsReaderImpl({required this._remote, required this._mapper});

  final AnalyticsRemoteDataSource _remote;
  final AnalyticsMapper _mapper;

  @override
  Future<Result<OccupancyHistory>> occupancy({
    required LotId lotId,
    required AnalyticsRange range,
    required OccupancyGranularity granularity,
    ZoneId? zoneId,
  }) => guardResult(() async {
    final dto = await _remote.occupancy(
      lotId: lotId,
      from: range.from,
      to: range.to,
      zoneId: zoneId,
      granularity: _mapper.granularityToApi(granularity),
    );
    return _mapper.toHistory(
      dto,
      lotId: lotId,
      range: range,
      requested: granularity,
      zoneId: zoneId,
    );
  });

  @override
  Future<Result<PeakHours>> peaks({
    required LotId lotId,
    required AnalyticsRange range,
  }) => guardResult(() async {
    final dto = await _remote.peaks(
      lotId: lotId,
      from: range.from,
      to: range.to,
    );
    return _mapper.toPeaks(dto);
  });

  @override
  Future<Result<ForecastAccuracy>> accuracy({
    required LotId lotId,
    required AnalyticsRange range,
  }) => guardResult(() async {
    final dtos = await _remote.accuracy(
      lotId: lotId,
      from: range.from,
      to: range.to,
    );
    return _mapper.toAccuracy(dtos);
  });
}

/// Envía la solicitud de reporte (`POST /analytics/reports`).
class ReportExporterImpl implements ReportExporter {
  const ReportExporterImpl({required this._remote, required this._mapper});

  final AnalyticsRemoteDataSource _remote;
  final AnalyticsMapper _mapper;

  @override
  Future<Result<ReportDelivery>> export(ReportRequest request) =>
      guardResult(() async {
        final dto = await _remote.exportReport(_mapper.toRequest(request));
        return _mapper.toDelivery(dto);
      });
}

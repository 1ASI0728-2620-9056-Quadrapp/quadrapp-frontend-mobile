import 'package:dio/dio.dart';
import 'package:quadrapp_mobile/contexts/analytics/infrastructure/datasources/analytics_remote_datasource.dart';
import 'package:quadrapp_mobile/contexts/analytics/infrastructure/dto/analytics_dtos.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/network/parse_exception.dart';

/// `GET /analytics/occupancy`, `/analytics/peaks`, `/analytics/accuracy` y
/// `POST /analytics/reports` (docs/07).
class AnalyticsHttpDataSource implements AnalyticsRemoteDataSource {
  const AnalyticsHttpDataSource(this._dio);

  final Dio _dio;

  static Map<String, Object> _range(LotId lotId, DateTime from, DateTime to) =>
      {
        'lotId': lotId.value,
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
      };

  Future<Map<String, dynamic>> _object(
    String path,
    Map<String, Object> query,
    String what,
  ) async {
    final response = await _dio.get<Object?>(path, queryParameters: query);
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw ParseException('$what no es un objeto.');
    }
    return data;
  }

  @override
  Future<OccupancyHistoryDto> occupancy({
    required LotId lotId,
    required DateTime from,
    required DateTime to,
    required String granularity,
    ZoneId? zoneId,
  }) async {
    final data = await _object('/analytics/occupancy', {
      ..._range(lotId, from, to),
      'granularity': granularity,
      if (zoneId != null) 'zoneId': zoneId.value,
    }, 'El historial de ocupación');
    return OccupancyHistoryDto.fromJson(data);
  }

  @override
  Future<PeakHoursDto> peaks({
    required LotId lotId,
    required DateTime from,
    required DateTime to,
  }) async {
    final data = await _object(
      '/analytics/peaks',
      _range(lotId, from, to),
      'Las horas pico',
    );
    return PeakHoursDto.fromJson(data);
  }

  @override
  Future<List<AccuracyResultDto>> accuracy({
    required LotId lotId,
    required DateTime from,
    required DateTime to,
  }) async {
    final response = await _dio.get<Object?>(
      '/analytics/accuracy',
      queryParameters: _range(lotId, from, to),
    );
    final data = response.data;
    if (data is! List) {
      throw const ParseException(
        'La precisión del pronóstico no es una lista.',
      );
    }
    return [
      for (final item in data)
        if (item is Map<String, dynamic>)
          AccuracyResultDto.fromJson(item)
        else
          throw const ParseException(
            'Un resultado de precisión no es un objeto.',
          ),
    ];
  }

  @override
  Future<ReportDeliveryDto> exportReport(ReportRequestDto request) async {
    final response = await _dio.post<Object?>(
      '/analytics/reports',
      data: request.toJson(),
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const ParseException('La respuesta del reporte no es un objeto.');
    }
    return ReportDeliveryDto.fromJson(data);
  }
}

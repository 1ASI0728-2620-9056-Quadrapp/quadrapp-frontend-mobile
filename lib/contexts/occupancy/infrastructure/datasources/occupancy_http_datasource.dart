import 'package:dio/dio.dart';
import 'package:quadrapp_mobile/contexts/occupancy/infrastructure/datasources/occupancy_remote_datasource.dart';
import 'package:quadrapp_mobile/contexts/occupancy/infrastructure/dto/lot_occupancy_dto.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/network/parse_exception.dart';

/// `GET /parking-lots/{lotId}/occupancy`.
class OccupancyHttpDataSource implements OccupancyRemoteDataSource {
  const OccupancyHttpDataSource(this._dio);

  final Dio _dio;

  @override
  Future<LotOccupancyDto> fetch(LotId lotId) async {
    final response = await _dio.get<Object?>(
      '/parking-lots/${lotId.value}/occupancy',
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const ParseException('La ocupación no es un objeto JSON.');
    }
    return LotOccupancyDto.fromJson(data);
  }
}

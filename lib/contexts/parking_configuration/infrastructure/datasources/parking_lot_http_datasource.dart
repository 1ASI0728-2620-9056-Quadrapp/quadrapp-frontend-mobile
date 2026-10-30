import 'package:dio/dio.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/datasources/parking_lot_remote_datasource.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/dto/parking_lot_dto.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/network/parse_exception.dart';

/// `GET /parking-lots` y `GET /parking-lots/{lotId}`.
class ParkingLotHttpDataSource implements ParkingLotRemoteDataSource {
  const ParkingLotHttpDataSource(this._dio);

  final Dio _dio;

  @override
  Future<List<ParkingLotDto>> list() async {
    final response = await _dio.get<Object?>('/parking-lots');
    final data = response.data;
    if (data is! List<dynamic>) {
      throw const ParseException(
        'La lista de estacionamientos no es un arreglo.',
      );
    }
    return [
      for (final item in data)
        ParkingLotDto.fromJson(item as Map<String, dynamic>),
    ];
  }

  @override
  Future<ParkingLotDto> get(LotId lotId) async {
    final response = await _dio.get<Object?>('/parking-lots/${lotId.value}');
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const ParseException('El estacionamiento no es un objeto JSON.');
    }
    return ParkingLotDto.fromJson(data);
  }
}

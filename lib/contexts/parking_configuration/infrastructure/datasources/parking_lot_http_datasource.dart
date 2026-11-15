import 'package:dio/dio.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/datasources/parking_lot_remote_datasource.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/dto/parking_lot_dto.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/network/parse_exception.dart';

/// La versión de distribución que ve la app. El backend todavía no tiene un
/// paso de publicación: todo estacionamiento registrado queda en
/// `layoutVersion` 0. Para la app, un estacionamiento del backend siempre
/// tiene una distribución legible (versión 1 como mínimo).
int effectiveLayoutVersion(int backendVersion) =>
    backendVersion < 1 ? 1 : backendVersion;

/// `GET /parking-lots` (los de la institución del usuario) y
/// `GET /parking-lots/{lotId}`: `ParkingLotResource` del backend. Solo se
/// muestran los estacionamientos activos.
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
        if (item is! Map<String, dynamic> || item['active'] != false)
          _dto(item as Map<String, dynamic>),
    ];
  }

  @override
  Future<ParkingLotDto> get(LotId lotId) async {
    final response = await _dio.get<Object?>('/parking-lots/${lotId.value}');
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const ParseException('El estacionamiento no es un objeto JSON.');
    }
    return _dto(data);
  }

  static ParkingLotDto _dto(Map<String, dynamic> json) {
    final dto = ParkingLotDto.fromJson(json);
    return ParkingLotDto(
      id: dto.id,
      name: dto.name,
      address: dto.address,
      latitude: dto.latitude,
      longitude: dto.longitude,
      layoutVersion: effectiveLayoutVersion(dto.layoutVersion),
      staleAfterSeconds: dto.staleAfterSeconds,
      saturationThresholdPct: dto.saturationThresholdPct,
    );
  }
}

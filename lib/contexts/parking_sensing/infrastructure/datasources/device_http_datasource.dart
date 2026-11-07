import 'package:dio/dio.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/infrastructure/datasources/device_remote_datasource.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/infrastructure/dto/device_dtos.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/network/parse_exception.dart';

/// `GET /devices/health`, `POST /devices` y `DELETE /devices/{id}` (docs/07).
class DeviceHttpDataSource implements DeviceRemoteDataSource {
  const DeviceHttpDataSource(this._dio);

  final Dio _dio;

  @override
  Future<DeviceHealthDto> health(LotId lotId) async {
    final response = await _dio.get<Object?>(
      '/devices/health',
      queryParameters: {'lotId': lotId.value},
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const ParseException(
        'La salud de los dispositivos no es un objeto.',
      );
    }
    return DeviceHealthDto.fromJson(data);
  }

  @override
  Future<DeviceDto> register(RegisterDeviceRequestDto request) async {
    final response = await _dio.post<Object?>(
      '/devices',
      data: request.toJson(),
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const ParseException('El dispositivo registrado no es un objeto.');
    }
    return DeviceDto.fromJson(data);
  }

  @override
  Future<void> decommission(DeviceId id) async {
    await _dio.delete<Object?>('/devices/${id.value}');
  }
}

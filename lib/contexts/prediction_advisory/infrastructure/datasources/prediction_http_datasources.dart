import 'package:dio/dio.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/infrastructure/datasources/prediction_remote_datasources.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/infrastructure/dto/prediction_dtos.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/network/parse_exception.dart';

Map<String, dynamic> _asObject(Object? data, String what) {
  if (data is! Map<String, dynamic>) {
    throw ParseException('$what no es un objeto JSON.');
  }
  return data;
}

/// `GET /forecasts?lotId=&horizon=`.
class ForecastHttpDataSource implements ForecastRemoteDataSource {
  const ForecastHttpDataSource(this._dio);

  final Dio _dio;

  @override
  Future<ForecastDto> fetch(LotId lotId, int horizonMinutes) async {
    final response = await _dio.get<Object?>(
      '/forecasts',
      queryParameters: {'lotId': lotId.value, 'horizon': horizonMinutes},
    );
    return ForecastDto.fromJson(_asObject(response.data, 'El pronóstico'));
  }
}

/// `POST /arrival-advices`. El cuerpo es exactamente el JSON de
/// [ArrivalAdviceRequestDto]: `lotId` y `etaMinutes`.
class ArrivalAdviceHttpDataSource implements ArrivalAdviceRemoteDataSource {
  const ArrivalAdviceHttpDataSource(this._dio);

  final Dio _dio;

  @override
  Future<ArrivalAdviceDto> request(ArrivalAdviceRequestDto request) async {
    final response = await _dio.post<Object?>(
      '/arrival-advices',
      data: request.toJson(),
    );
    return ArrivalAdviceDto.fromJson(_asObject(response.data, 'La asesoría'));
  }
}

/// `GET /forecasts/{lotId}/next-availability`.
class NextAvailabilityHttpDataSource
    implements NextAvailabilityRemoteDataSource {
  const NextAvailabilityHttpDataSource(this._dio);

  final Dio _dio;

  @override
  Future<NextAvailabilityDto> fetch(LotId lotId) async {
    final response = await _dio.get<Object?>(
      '/forecasts/${lotId.value}/next-availability',
    );
    return NextAvailabilityDto.fromJson(
      _asObject(response.data, 'La próxima liberación'),
    );
  }
}

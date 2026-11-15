import 'dart:io';

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

/// Pronóstico de un horizonte con la última corrida del backend:
/// `GET /parking-lots/{lotId}/forecasts` devuelve una `ForecastResource` por
/// horizonte (15, 30, 45 y 60 min) y aquí se elige la pedida. Sin ella, la
/// respuesta es un 404 como el de un horizonte sin pronóstico.
///
/// Lo que el backend no trae se deriva:
/// - `validUntil`: el inicio de la corrida (`runSlot`, o `generatedAt`) más
///   [validity]; el backend genera una corrida cada 5 minutos.
/// - `serverTime`: la cabecera `Date` de la respuesta (o `generatedAt`).
/// - `saturation.pct`: el umbral de saturación del estacionamiento
///   (`GET /parking-lots/{lotId}`), solo si hay `saturationExpectedAt`.
class ForecastHttpDataSource implements ForecastRemoteDataSource {
  const ForecastHttpDataSource(this._dio);

  final Dio _dio;

  /// Cuánto vale una corrida: dos intervalos del planificador del backend.
  static const validity = Duration(minutes: 10);

  @override
  Future<ForecastDto> fetch(LotId lotId, int horizonMinutes) async {
    final response = await _dio.get<Object?>(
      '/parking-lots/${lotId.value}/forecasts',
    );
    final data = response.data;
    if (data is! List<dynamic>) {
      throw const ParseException('Los pronósticos no son un arreglo.');
    }
    final forecast = data
        .map((item) => _asObject(item, 'El pronóstico'))
        .where((item) => item['horizonMinutes'] == horizonMinutes)
        .firstOrNull;
    if (forecast == null) {
      throw DioException.badResponse(
        statusCode: 404,
        requestOptions: response.requestOptions,
        response: Response<Object?>(
          requestOptions: response.requestOptions,
          statusCode: 404,
        ),
      );
    }
    final generatedAt = _instant(forecast['generatedAt'], 'generatedAt');
    final runSlot = forecast['runSlot'] == null
        ? generatedAt
        : _instant(forecast['runSlot'], 'runSlot');
    final saturationAt = forecast['saturationExpectedAt'];
    return ForecastDto(
      horizon: horizonMinutes,
      expectedOccupancyPct: _number(forecast, 'expectedOccupancyPct'),
      confidence: ConfidenceDto(
        value: _number(forecast, 'confidence'),
        level: forecast['confidenceLevel'] as String? ?? '',
      ),
      modelVersion: forecast['modelVersion'] as String? ?? '',
      method: forecast['method'] as String? ?? '',
      generatedAt: generatedAt,
      validUntil: runSlot.add(validity),
      serverTime: _serverTime(response) ?? generatedAt,
      saturation: saturationAt == null
          ? null
          : SaturationDto(
              expectedAt: _instant(saturationAt, 'saturationExpectedAt'),
              pct: await _saturationThreshold(lotId),
            ),
    );
  }

  Future<double> _saturationThreshold(LotId lotId) async {
    final lot = _asObject(
      (await _dio.get<Object?>('/parking-lots/${lotId.value}')).data,
      'El estacionamiento',
    );
    return _number(lot, 'saturationThresholdPct');
  }

  static DateTime? _serverTime(Response<Object?> response) {
    final date = response.headers.value('date');
    if (date == null) return null;
    try {
      return HttpDate.parse(date);
    } on FormatException {
      return null;
    }
  }

  static double _number(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is! num) throw ParseException('El campo $field no es válido.');
    return value.toDouble();
  }

  static DateTime _instant(Object? value, String field) {
    final parsed = value is String ? DateTime.tryParse(value) : null;
    if (parsed == null) throw ParseException('El campo $field no es válido.');
    return parsed;
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

/// La próxima liberación. El backend todavía no la calcula (no hay una ruta
/// equivalente a `GET /forecasts/{lotId}/next-availability`): responde
/// siempre «sin estimación», sin llamar a la red.
class UnavailableNextAvailabilityDataSource
    implements NextAvailabilityRemoteDataSource {
  const UnavailableNextAvailabilityDataSource();

  @override
  Future<NextAvailabilityDto> fetch(LotId lotId) async =>
      NextAvailabilityDto(available: false, serverTime: DateTime.now().toUtc());
}

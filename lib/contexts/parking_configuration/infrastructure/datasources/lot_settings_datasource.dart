import 'package:dio/dio.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/dto/lot_settings_dto.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/network/parse_exception.dart';

/// Origen remoto de la configuración propia de un estacionamiento (HTTP o
/// mock).
// ignore: one_member_abstracts
abstract interface class LotSettingsRemoteDataSource {
  /// `PATCH /parking-lots/{lotId}`.
  Future<LotSettingsDto> update(LotId lotId, LotSettingsDto settings);
}

/// `PATCH /parking-lots/{lotId}`.
class LotSettingsHttpDataSource implements LotSettingsRemoteDataSource {
  const LotSettingsHttpDataSource(this._dio);

  final Dio _dio;

  @override
  Future<LotSettingsDto> update(LotId lotId, LotSettingsDto settings) async {
    final response = await _dio.patch<Object?>(
      '/parking-lots/${lotId.value}',
      data: settings.toJson(),
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const ParseException('La configuración no devolvió un objeto.');
    }
    return LotSettingsDto.fromJson(data);
  }
}

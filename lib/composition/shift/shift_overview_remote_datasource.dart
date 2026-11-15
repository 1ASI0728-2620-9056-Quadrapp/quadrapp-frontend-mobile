// TS17
import 'package:dio/dio.dart';
import 'package:quadrapp_mobile/composition/shift/shift_overview_dto.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/network/parse_exception.dart';

/// Origen remoto del estado de operación (HTTP o mock).
// ignore: one_member_abstracts
abstract interface class ShiftOverviewRemoteDataSource {
  /// `GET /console/overview?lotId=`.
  Future<ShiftOverviewDto> fetch(LotId lotId);
}

/// `GET /console/overview`.
class ShiftOverviewHttpDataSource implements ShiftOverviewRemoteDataSource {
  const ShiftOverviewHttpDataSource(this._dio);

  final Dio _dio;

  @override
  Future<ShiftOverviewDto> fetch(LotId lotId) async {
    final response = await _dio.get<Object?>(
      '/console/overview',
      queryParameters: {'lotId': lotId.value},
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const ParseException('El resumen de consola no es un objeto.');
    }
    return ShiftOverviewDto.fromJson(data);
  }
}

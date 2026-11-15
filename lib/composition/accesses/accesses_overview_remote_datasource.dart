// US19, US29
import 'package:dio/dio.dart';
import 'package:quadrapp_mobile/composition/accesses/accesses_overview_dto.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/network/parse_exception.dart';

/// Origen remoto de los accesos vehiculares (HTTP o mock).
// ignore: one_member_abstracts
abstract interface class AccessesOverviewRemoteDataSource {
  /// `GET /console/accesses?lotId=`.
  Future<AccessesOverviewDto> fetch(LotId lotId);
}

/// `GET /console/accesses`.
class AccessesOverviewHttpDataSource
    implements AccessesOverviewRemoteDataSource {
  const AccessesOverviewHttpDataSource(this._dio);

  final Dio _dio;

  @override
  Future<AccessesOverviewDto> fetch(LotId lotId) async {
    final response = await _dio.get<Object?>(
      '/console/accesses',
      queryParameters: {'lotId': lotId.value},
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const ParseException('Los accesos no son un objeto.');
    }
    return AccessesOverviewDto.fromJson(data);
  }
}

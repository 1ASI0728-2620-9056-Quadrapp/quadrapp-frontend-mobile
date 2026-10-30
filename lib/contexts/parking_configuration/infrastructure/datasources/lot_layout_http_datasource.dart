import 'package:dio/dio.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/datasources/lot_layout_remote_datasource.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/dto/lot_layout_dto.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/network/parse_exception.dart';

/// `GET /parking-lots/{lotId}/layout` con `If-None-Match: "v4"`.
class LotLayoutHttpDataSource implements LotLayoutRemoteDataSource {
  const LotLayoutHttpDataSource(this._dio);

  final Dio _dio;

  @override
  Future<LayoutFetch> fetch(LotId lotId, {int? knownVersion}) async {
    final response = await _dio.get<Object?>(
      '/parking-lots/${lotId.value}/layout',
      options: Options(
        headers: {
          if (knownVersion != null) 'If-None-Match': '"v$knownVersion"',
        },
        // Un 304 no es un error: conserva la copia local.
        validateStatus: (status) =>
            status != null &&
            ((status >= 200 && status < 300) || status == 304),
      ),
    );
    if (response.statusCode == 304) return const LayoutNotModified();
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const ParseException('La distribución no es un objeto JSON.');
    }
    return LayoutFetched(LotLayoutDto.fromJson(data));
  }
}

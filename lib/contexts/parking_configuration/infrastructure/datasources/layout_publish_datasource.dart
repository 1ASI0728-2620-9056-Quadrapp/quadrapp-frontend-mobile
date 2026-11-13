import 'package:dio/dio.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/dto/publish_layout_dto.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/network/parse_exception.dart';

/// Origen remoto de la publicación de la distribución (HTTP o mock).
// ignore: one_member_abstracts
abstract interface class LayoutPublishRemoteDataSource {
  /// `POST /parking-lots/{lotId}/layout/publish`.
  Future<PublishLayoutResponseDto> publish(
    LotId lotId,
    PublishLayoutRequestDto request,
  );
}

/// `POST /parking-lots/{lotId}/layout/publish`.
class LayoutPublishHttpDataSource implements LayoutPublishRemoteDataSource {
  const LayoutPublishHttpDataSource(this._dio);

  final Dio _dio;

  @override
  Future<PublishLayoutResponseDto> publish(
    LotId lotId,
    PublishLayoutRequestDto request,
  ) async {
    final response = await _dio.post<Object?>(
      '/parking-lots/${lotId.value}/layout/publish',
      data: request.toJson(),
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const ParseException('La publicación no devolvió un objeto.');
    }
    return PublishLayoutResponseDto.fromJson(data);
  }
}

import 'package:dio/dio.dart';

/// Un error de `dio` con la misma forma que el de una respuesta real, para que
/// los mocks fallen igual que el backend (mismos `Failure`).
DioException mockDioError(
  DioExceptionType type, {
  int? status,
  Object? data,
  String path = '/mock',
  Map<String, List<String>> headers = const {},
}) {
  final options = RequestOptions(path: path);
  return DioException(
    requestOptions: options,
    type: type,
    response: status == null
        ? null
        : Response<dynamic>(
            requestOptions: options,
            statusCode: status,
            data: data,
            headers: Headers.fromMap(headers),
          ),
  );
}

/// Un error HTTP con cuerpo `application/problem+json`.
DioException mockHttpError(
  int status, {
  String? title,
  String? detail,
  Map<String, Object?> extra = const {},
  String path = '/mock',
}) {
  return mockDioError(
    DioExceptionType.badResponse,
    status: status,
    path: path,
    data: {
      'type': 'about:blank',
      'title': title ?? 'Error $status',
      'status': status,
      'detail': ?detail,
      ...extra,
    },
  );
}

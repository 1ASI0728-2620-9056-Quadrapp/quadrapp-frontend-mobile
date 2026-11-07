import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Responde una petición.
typedef HttpHandler = FutureOr<ResponseBody> Function(RequestOptions options);

/// Adaptador de `dio` falso: guarda las peticiones y responde con [handler].
class FakeHttpAdapter implements HttpClientAdapter {
  FakeHttpAdapter(this.handler);

  HttpHandler handler;
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

/// Respuesta JSON.
ResponseBody jsonResponse(
  Object? body, {
  int status = 200,
  Map<String, List<String>> headers = const {},
}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
      ...headers,
    },
  );
}

/// Respuesta sin cuerpo (204, 304).
ResponseBody emptyResponse(
  int status, {
  Map<String, List<String>> headers = const {},
}) => ResponseBody.fromString('', status, headers: headers);

/// Un `Dio` que usa [adapter].
Dio dioWith(
  FakeHttpAdapter adapter, {
  List<Interceptor> interceptors = const [],
}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))
    ..httpClientAdapter = adapter;
  dio.interceptors.addAll(interceptors);
  return dio;
}

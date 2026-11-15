import 'package:dio/dio.dart';

/// Tiempo máximo de espera para conectar, enviar y recibir.
const httpTimeout = Duration(seconds: 15);

/// Crea el cliente HTTP base con los [interceptors] recibidos.
///
/// Regla fija: ningún interceptor de logs puede registrar contraseñas, códigos
/// OTP, tokens ni el header `Authorization` (ver `SafeLogInterceptor`).
Dio createDio({
  required String baseUrl,
  List<Interceptor> interceptors = const [],
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: httpTimeout,
      sendTimeout: httpTimeout,
      receiveTimeout: httpTimeout,
      headers: {Headers.acceptHeader: Headers.jsonContentType},
    ),
  );
  dio.interceptors.addAll(interceptors);
  return dio;
}

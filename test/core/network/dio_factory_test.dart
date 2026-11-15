import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/core/network/dio_factory.dart';

void main() {
  test('createDio configura URL base, tiempos de espera y Accept', () {
    final dio = createDio(baseUrl: 'https://x.test/api/v1');

    expect(dio.options.baseUrl, 'https://x.test/api/v1');
    expect(dio.options.connectTimeout, httpTimeout);
    expect(dio.options.sendTimeout, httpTimeout);
    expect(dio.options.receiveTimeout, httpTimeout);
    expect(dio.options.headers['accept'], 'application/json');
  });

  test('createDio no agrega interceptor de logs', () {
    final dio = createDio(baseUrl: 'https://x.test');

    expect(dio.interceptors.any((i) => i is LogInterceptor), isFalse);
  });
}

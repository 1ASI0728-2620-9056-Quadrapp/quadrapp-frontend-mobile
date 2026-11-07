import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/app/config/app_config.dart';

void main() {
  group('AppConfig.fromEnvironment', () {
    test(
      'usa mocks en debug cuando no se define USE_MOCKS',
      () {
        expect(AppConfig.fromEnvironment().useMocks, isTrue);
      },
      skip: const bool.hasEnvironment('USE_MOCKS')
          ? 'USE_MOCKS definido por --dart-define'
          : false,
    );

    test(
      'apunta al localhost del emulador cuando no se define API_BASE_URL',
      () {
        expect(
          AppConfig.fromEnvironment().apiBaseUrl,
          AppConfig.defaultApiBaseUrl,
        );
      },
      skip: const bool.hasEnvironment('API_BASE_URL')
          ? 'API_BASE_URL definido por --dart-define'
          : false,
    );
  });
}

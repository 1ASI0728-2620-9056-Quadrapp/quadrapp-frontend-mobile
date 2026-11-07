import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:quadrapp_mobile/app/config/app_config.dart';
import 'package:quadrapp_mobile/app/di/injector.dart';
import '../../helpers/test_seed.dart';

void main() {
  late GetIt locator;

  setUp(() {
    locator = GetIt.asNewInstance();
  });

  tearDown(() async {
    await locator.reset();
  });

  test('registra la configuración recibida', () async {
    const config = AppConfig(useMocks: false, apiBaseUrl: 'https://x.test/v1');

    await configureDependencies(
      config: config,
      locator: locator,
      mockSeed: testSeed,
    );

    expect(locator<AppConfig>(), same(config));
    expect(locator<AppConfig>().useMocks, isFalse);
  });

  test('registra un Dio con la URL base de la configuración', () async {
    const config = AppConfig(useMocks: true, apiBaseUrl: 'https://x.test/v1');

    await configureDependencies(
      config: config,
      locator: locator,
      mockSeed: testSeed,
    );

    final dio = locator<Dio>();
    expect(dio.options.baseUrl, 'https://x.test/v1');
    expect(dio, same(locator<Dio>()));
  });
}

import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:quadrapp_mobile/app/app.dart';
import 'package:quadrapp_mobile/app/config/app_config.dart';
import 'package:quadrapp_mobile/app/di/injector.dart';
import 'package:quadrapp_mobile/app/mocks/mock_controls.dart';
import 'package:quadrapp_mobile/app/startup.dart';
import 'package:quadrapp_mobile/core/storage/key_value_store.dart';
import 'package:quadrapp_mobile/core/storage/secure_store.dart';
import 'test_seed.dart';

/// La app completa con los mocks y los almacenes en memoria, para probar el
/// router y las pantallas con los casos de uso reales. Sin latencia simulada ni
/// simulador de espacios: no deja temporizadores pendientes.
class AppHarness {
  AppHarness._(this.locator, this.router, this.values, this.secrets);

  final GetIt locator;
  final GoRouter router;
  final InMemoryKeyValueStore values;
  final InMemorySecureStore secrets;

  MockControls get controls => locator<MockControls>();

  static Future<AppHarness> create({
    bool enableGallery = false,
    bool enableDebugPanel = false,
    InMemoryKeyValueStore? values,
    InMemorySecureStore? secrets,
    Future<void> Function(GetIt locator)? seed,
  }) async {
    final keyValues = values ?? InMemoryKeyValueStore();
    final secretValues = secrets ?? InMemorySecureStore();
    final locator = GetIt.asNewInstance();
    await configureDependencies(
      config: const AppConfig(useMocks: true, apiBaseUrl: 'https://x.test'),
      locator: locator,
      keyValueStore: keyValues,
      secureStore: secretValues,
      mockLatency: false,
      mockSeed: testSeed,
    );
    // Lo que ya está en el dispositivo cuando la app abre (por ejemplo, una
    // sesión guardada).
    await seed?.call(locator);
    startAppServices(locator, startSimulator: false);
    final router = createRouterFrom(
      locator,
      enableGallery: enableGallery,
      enableDebugPanel: enableDebugPanel,
    );
    return AppHarness._(locator, router, keyValues, secretValues);
  }

  Widget app({Locale? locale, bool showDebugEntry = false}) => QuadrappApp(
    router: router,
    locale: locale,
    showDebugEntry: showDebugEntry,
  );

  Future<void> dispose() async {
    router.dispose();
    await locator.reset();
  }
}

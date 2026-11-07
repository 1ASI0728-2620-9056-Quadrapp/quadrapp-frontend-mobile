import 'package:flutter/services.dart';
import 'package:get_it/get_it.dart';
import 'package:quadrapp_mobile/app/config/app_config.dart';
import 'package:quadrapp_mobile/app/di/alerts_module.dart';
import 'package:quadrapp_mobile/app/di/arrival_module.dart';
import 'package:quadrapp_mobile/app/di/auth_module.dart';
import 'package:quadrapp_mobile/app/di/core_module.dart';
import 'package:quadrapp_mobile/app/di/eta_module.dart';
import 'package:quadrapp_mobile/app/di/forecast_module.dart';
import 'package:quadrapp_mobile/app/di/iam_module.dart';
import 'package:quadrapp_mobile/app/di/notifications_module.dart';
import 'package:quadrapp_mobile/app/di/occupancy_module.dart';
import 'package:quadrapp_mobile/app/di/operations_module.dart';
import 'package:quadrapp_mobile/app/di/parking_configuration_module.dart';
import 'package:quadrapp_mobile/app/di/prediction_advisory_module.dart';
import 'package:quadrapp_mobile/app/di/sede_module.dart';
import 'package:quadrapp_mobile/app/di/sign_out_module.dart';
import 'package:quadrapp_mobile/app/di/zones_module.dart';
import 'package:quadrapp_mobile/app/mocks/mock_seed.dart';
import 'package:quadrapp_mobile/core/storage/key_value_store.dart';
import 'package:quadrapp_mobile/core/storage/secure_store.dart';

/// Localizador global. Solo se usa aquí, en la raíz de composición
/// (`lib/app/di/`); ninguna otra capa lo importa.
final GetIt getIt = GetIt.instance;

/// Registra todas las dependencias: `core`, un módulo por contexto
/// (`<contexto>_module.dart`, que lee `AppConfig.useMocks` para elegir entre
/// datasources mock y HTTP/WebSocket), la composición de `sign_out` y la
/// presentación del acceso (`auth_module`).
///
/// Registrar no construye nada: todo es perezoso, sin llamadas de red ni de
/// plugins hasta que se usa. [keyValueStore] y [secureStore] sustituyen los
/// almacenes reales y [mockLatency] la espera simulada de los mocks (pruebas).
/// Con mocks, los datos de prueba se leen de `assets/mocks/seed.json` salvo que
/// [mockSeed] los traiga ya leídos (pruebas).
Future<GetIt> configureDependencies({
  required AppConfig config,
  GetIt? locator,
  KeyValueStore? keyValueStore,
  SecureStore? secureStore,
  bool mockLatency = true,
  MockSeed? mockSeed,
}) async {
  final target = locator ?? getIt;
  final seed = config.useMocks
      ? mockSeed ?? await MockSeed.load(rootBundle)
      : null;
  registerCoreModule(
    target,
    config,
    keyValueStore: keyValueStore,
    secureStore: secureStore,
    mockLatency: mockLatency,
    mockSeed: seed,
  );
  registerIamModule(target, config);
  registerParkingConfigurationModule(target, config);
  registerOccupancyModule(target, config);
  registerPredictionAdvisoryModule(target, config);
  registerNotificationsModule(target, config);
  registerOperationsModule(target, config);
  registerSignOutModule(target);
  registerAuthModule(target);
  registerArrivalModule(target);
  registerZonesModule(target);
  registerForecastModule(target);
  registerAlertsModule(target);
  registerSedeModule(target);
  registerEtaModule(target, config);
  return target;
}

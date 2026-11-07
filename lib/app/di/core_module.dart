import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:quadrapp_mobile/app/config/app_config.dart';
import 'package:quadrapp_mobile/app/di/registrar.dart';
import 'package:quadrapp_mobile/app/l10n/locale_resolution.dart';
import 'package:quadrapp_mobile/app/mocks/mock_controls.dart';
import 'package:quadrapp_mobile/app/mocks/mock_seed.dart';
import 'package:quadrapp_mobile/app/mocks/mock_world.dart';
import 'package:quadrapp_mobile/app/session/session_token_source.dart';
import 'package:quadrapp_mobile/contexts/iam/application/usecases/expire_session.dart';
import 'package:quadrapp_mobile/core/logging/logger.dart';
import 'package:quadrapp_mobile/core/network/auth_interceptor.dart';
import 'package:quadrapp_mobile/core/network/dio_factory.dart';
import 'package:quadrapp_mobile/core/network/locale_interceptor.dart';
import 'package:quadrapp_mobile/core/network/safe_log_interceptor.dart';
import 'package:quadrapp_mobile/core/network/web_socket_connector.dart';
import 'package:quadrapp_mobile/core/storage/key_value_store.dart';
import 'package:quadrapp_mobile/core/storage/secure_store.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Dependencias transversales: configuración, reloj, registro de avisos,
/// almacenes, red y, solo con `USE_MOCKS=true`, el mundo simulado.
///
/// [keyValueStore] y [secureStore] permiten sustituir los almacenes (pruebas);
/// por defecto son `shared_preferences` y `flutter_secure_storage`.
/// [mockLatency] apaga la espera simulada de los mocks (pruebas). Con mocks,
/// [mockSeed] son los datos de prueba (`assets/mocks/seed.json`, ya leídos).
void registerCoreModule(
  GetIt locator,
  AppConfig config, {
  KeyValueStore? keyValueStore,
  SecureStore? secureStore,
  bool mockLatency = true,
  MockSeed? mockSeed,
}) {
  locator
    ..addValue<AppConfig>(config)
    ..addValue<Logger>(const DeveloperLogger())
    ..addLazy<KeyValueStore>(
      () => keyValueStore ?? SharedPreferencesStore(SharedPreferencesAsync()),
    )
    ..addLazy<SecureStore>(() => secureStore ?? const FlutterSecureStore())
    ..addLazy<WebSocketConnector>(() => const IoWebSocketConnector());

  // El reloj del servidor es el real; con mocks, el del teléfono puede
  // desfasarse con `MockControls.phoneClockSkew` (la antigüedad no debe
  // depender de él).
  final systemClock = SystemClock();
  if (config.useMocks) {
    locator
      ..addValue<MockControls>(MockControls())
      ..addLazy<MockWorld>(
        () => MockWorld(
          clock: systemClock,
          seed: mockSeed!,
          controls: locator<MockControls>(),
          latency: mockLatency,
        ),
        dispose: (world) => world.dispose(),
      )
      ..addLazy<Clock>(() => MockPhoneClock(systemClock, locator()));
  } else {
    locator.addValue<Clock>(systemClock);
  }

  locator.addLazy<Dio>(
    () {
      final dio = createDio(baseUrl: config.apiBaseUrl);
      dio.interceptors.addAll([
        LocaleInterceptor(currentLanguageCode),
        AuthInterceptor(
          dio: dio,
          tokens: _LazySessionTokens(locator),
          onSessionExpired: () => _confirmSessionExpired(locator),
        ),
        // Solo en debug, y solo método, ruta, estado y duración (nunca
        // cabeceras ni cuerpos).
        if (kDebugMode) SafeLogInterceptor(locator<Logger>()),
      ]);
      return dio;
    },
    dispose: (dio) => dio.close(),
  );
}

/// Idioma que se envía en `Accept-Language`. Hoy es el idioma inicial (inglés);
/// en la fase 6 pasa a leer la preferencia guardada del usuario.
String currentLanguageCode() => resolveLocale(null).languageCode;

/// Los tokens de `iam` usan el mismo `Dio` que este interceptor (el refresh y
/// el logout van por él): un ciclo. Se rompe resolviéndolos al primer uso y no
/// al construir el `Dio`.
class _LazySessionTokens implements AuthTokenSource {
  const _LazySessionTokens(this._locator);

  final GetIt _locator;

  SessionTokenSource get _source => _locator<SessionTokenSource>();

  @override
  String? get accessToken => _source.accessToken;

  @override
  Future<TokenRefresh> refreshAccessToken() => _source.refreshAccessToken();
}

/// Cuando el interceptor ve que el servidor rechazó el refresh, se asegura de
/// que la expiración quede registrada y avisada. `ExpireSession` es
/// idempotente: si `RefreshSession` ya la registró, no avisa otra vez.
void _confirmSessionExpired(GetIt locator) {
  unawaited(locator<ExpireSession>()(const NoParams()));
}

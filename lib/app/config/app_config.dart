import 'package:flutter/foundation.dart';

/// Configuración de ejecución, leída de `--dart-define`.
///
/// - `USE_MOCKS`: `true` registra los datasources mock en lugar de los HTTP y
///   WebSocket. Por defecto es `true` en debug y `false` en release.
/// - `API_BASE_URL`: URL base de la API. Por defecto apunta al localhost del
///   emulador de Android; no hay ningún servidor real por defecto.
/// - `ROUTES_API_KEY`: clave de Google Routes para el ETA con tráfico. Sin
///   clave (por defecto) no hay ETA con tráfico y la app usa la estimación
///   local. La clave viaja en la app: restríngela a la API Routes y ponle
///   cuota.
class AppConfig {
  const AppConfig({
    required this.useMocks,
    required this.apiBaseUrl,
    this.routesApiKey = '',
  });

  factory AppConfig.fromEnvironment() {
    const hasMocksDefine = bool.hasEnvironment('USE_MOCKS');
    return const AppConfig(
      useMocks: hasMocksDefine ? bool.fromEnvironment('USE_MOCKS') : kDebugMode,
      apiBaseUrl: String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: defaultApiBaseUrl,
      ),
    );
  }

  static const defaultApiBaseUrl = 'http://10.0.2.2:8080/api/v1';

  final bool useMocks;
  final String apiBaseUrl;
  final String routesApiKey;

  /// ¿Hay un proveedor de mapas para el ETA con tráfico? Con mocks, uno
  /// simulado.
  bool get hasTrafficProvider => useMocks || routesApiKey.isNotEmpty;
}

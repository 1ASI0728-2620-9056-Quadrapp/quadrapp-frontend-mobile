import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:quadrapp_mobile/app/app.dart';
import 'package:quadrapp_mobile/app/config/app_config.dart';
import 'package:quadrapp_mobile/app/di/injector.dart';
import 'package:quadrapp_mobile/app/startup.dart';
import 'package:quadrapp_mobile/app/theme/font_licenses.dart';

/// Inicializa la configuración y la inyección de dependencias, arranca los
/// servicios de la app (sesión, baja pendiente del token push) y muestra la
/// app.
///
/// Más adelante inicializará también Firebase.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  registerFontLicenses();
  final config = AppConfig.fromEnvironment();
  final locator = await configureDependencies(config: config);
  startAppServices(locator);
  runApp(
    QuadrappApp(
      router: createRouterFrom(locator),
      // El acceso al panel de depuración: nunca en release.
      showDebugEntry: kDebugMode && config.useMocks,
    ),
  );
}

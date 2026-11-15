import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/app/theme/app_theme.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';

/// Monta [screen] como pantalla completa (sin el `Scaffold` ni el relleno de
/// `pumpInApp`), con el tema, los idiomas y los ajustes de accesibilidad de la
/// app. Para probar y fotografiar pantallas enteras.
///
/// [keyboardHeight] simula el teclado abierto (`viewInsets`); [statusBar] y
/// [navigationBar] son los insets del sistema (modo de borde a borde), todos
/// en dp. [pixelRatio] sube la densidad (las capturas usan 2).
Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  Brightness brightness = Brightness.light,
  Locale locale = const Locale('en'),
  double textScale = 1,
  Size size = const Size(360, 800),
  double keyboardHeight = 0,
  double statusBar = 24,
  double navigationBar = 24,
  bool disableAnimations = true,
  double pixelRatio = 1,
}) async {
  // Los insets de `FakeViewPadding` van en píxeles físicos.
  FakeViewPadding insets({double top = 0, double bottom = 0}) =>
      FakeViewPadding(top: top * pixelRatio, bottom: bottom * pixelRatio);
  tester.view
    ..physicalSize = size * pixelRatio
    ..devicePixelRatio = pixelRatio
    ..padding = insets(top: statusBar, bottom: navigationBar)
    ..viewPadding = insets(top: statusBar, bottom: navigationBar)
    ..viewInsets = insets(bottom: keyboardHeight);
  addTearDown(tester.view.reset);

  if (disableAnimations) {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  }

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      locale: locale,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: app!,
      ),
      home: screen,
    ),
  );
  await tester.pump();
}

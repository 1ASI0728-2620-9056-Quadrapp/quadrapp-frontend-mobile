import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/app/theme/app_theme.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';

/// Monta [child] dentro de una `MaterialApp` con el tema, los idiomas y los
/// ajustes de accesibilidad de la app, para probar componentes.
Future<void> pumpInApp(
  WidgetTester tester,
  Widget child, {
  Brightness brightness = Brightness.light,
  Locale locale = const Locale('en'),
  double textScale = 1,
  Size size = const Size(400, 900),
  bool disableAnimations = true,
  bool scrollable = true,
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
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
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, app) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: app!,
      ),
      home: Scaffold(
        body: scrollable
            ? SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: child,
              )
            : Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  );
  await tester.pump();
}

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/contexts/iam/presentation/pages/login_page.dart';

import '../helpers/app_harness.dart';

void main() {
  Future<Locale> pumpApp(
    WidgetTester tester, {
    Locale? deviceLocale,
    Locale? preferred,
  }) async {
    if (deviceLocale != null) {
      tester.platformDispatcher.localesTestValue = [deviceLocale];
      addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    }

    final harness = await AppHarness.create();
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.app(locale: preferred));
    await tester.pumpAndSettle();

    return Localizations.localeOf(tester.element(find.byType(LoginPage)));
  }

  group('idioma', () {
    testWidgets('primer arranque en inglés con el teléfono en español', (
      tester,
    ) async {
      final locale = await pumpApp(tester, deviceLocale: const Locale('es'));

      expect(locale, const Locale('en'));
    });

    testWidgets('teléfono en otro idioma usa inglés', (tester) async {
      final locale = await pumpApp(tester, deviceLocale: const Locale('fr'));

      expect(locale, const Locale('en'));
    });

    testWidgets('la preferencia del usuario tiene prioridad', (tester) async {
      final locale = await pumpApp(
        tester,
        deviceLocale: const Locale('en'),
        preferred: const Locale('es'),
      );

      expect(locale, const Locale('es'));
    });
  });

  group('smoke test', () {
    testWidgets('sin sesión, abre el acceso en inglés', (tester) async {
      await pumpApp(tester, preferred: const Locale('en'));

      expect(find.text('Plan your arrival at campus'), findsOneWidget);
    });

    testWidgets('sin sesión, abre el acceso en español', (tester) async {
      await pumpApp(tester, preferred: const Locale('es'));

      expect(find.text('Anticipa tu llegada al campus'), findsOneWidget);
    });
  });
}

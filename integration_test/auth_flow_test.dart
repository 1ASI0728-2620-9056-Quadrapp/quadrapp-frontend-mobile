// US01 (esc. 1, 2), US02 (esc. 1, 2): el flujo feliz de acceso, de punta a
// punta y contra los mocks, en un dispositivo o emulador:
//
//   flutter test integration_test --dart-define=USE_MOCKS=true
//
// Los demás escenarios de Gherkin son de la Fase 7.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:quadrapp_mobile/core/storage/secure_store.dart';
import 'package:quadrapp_mobile/main.dart' as app;
import 'package:shared_preferences/shared_preferences.dart';

/// Con la latencia simulada de los mocks (200 a 600 ms) `pumpAndSettle` puede
/// volver antes de que llegue la respuesta: se espera de verdad a [finder].
Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (finder.evaluate().isEmpty) {
    if (DateTime.now().isAfter(deadline)) {
      throw TestFailure('No apareció: $finder');
    }
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.pumpAndSettle();
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'flujo feliz: correo, código, /lots y cerrar sesión',
    (tester) async {
      // Un dispositivo limpio: sin sesión de una ejecución anterior.
      await const FlutterSecureStore().deleteAll();
      await SharedPreferencesAsync().clear();

      await app.main();
      await tester.pumpAndSettle();

      // /login: el correo.
      await _pumpUntilFound(tester, find.text('Continue'));
      await tester.enterText(
        find.byType(TextFormField),
        'conductor@upc.edu.pe',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));

      // /login/verify: el código (se envía solo al completar los 6 dígitos).
      await _pumpUntilFound(tester, find.text('Verify your email'));
      expect(
        find.text('We sent a 6-digit code to conductor@upc.edu.pe.'),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextField), '123456');

      // /lots: la sesión quedó iniciada y se ve la lista.
      await _pumpUntilFound(tester, find.text('Monterrico'));

      // US02: cerrar sesión (en Ajustes), con confirmación.
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
      await tester.pumpAndSettle();
      expect(find.text('Sign out?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Sign out').last);

      // De vuelta en /login; el dispositivo ya no guarda la sesión.
      await _pumpUntilFound(tester, find.text('Continue'));
      expect(find.text('Monterrico'), findsNothing);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

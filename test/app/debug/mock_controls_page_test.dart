// Panel de depuración: solo en debug con mocks, nunca en release.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/app/debug/mock_controls_page.dart';
import 'package:quadrapp_mobile/app/mocks/mock_world.dart';
import 'package:quadrapp_mobile/composition/arrival/home_page.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/repositories/session_store.dart';
import 'package:quadrapp_mobile/contexts/iam/presentation/pages/login_page.dart';

import '../../contexts/iam/support.dart';
import '../../helpers/app_harness.dart';

void main() {
  late AppHarness harness;

  Future<void> start(
    WidgetTester tester, {
    bool debug = true,
    bool signedIn = false,
  }) async {
    tester.view
      ..physicalSize = const Size(400, 3600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    harness = await AppHarness.create(
      enableGallery: debug,
      enableDebugPanel: debug,
      seed: signedIn
          ? (locator) async {
              await locator<SessionStore>().save(sampleStored());
              // El servidor de mocks debe conocer ese refresh token.
              locator<MockWorld>().iam.refreshTokens.add('refresh-1');
            }
          : null,
    );
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.app(showDebugEntry: debug));
    await tester.pumpAndSettle();
  }

  group('en debug con mocks', () {
    testWidgets('el acceso abre el panel, también sin sesión', (tester) async {
      await start(tester);
      expect(find.byType(LoginPage), findsOneWidget);

      await tester.tap(find.byIcon(Icons.bug_report_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(MockControlsPage), findsOneWidget);
      expect(
        find.textContaining('conductor@upc.edu.pe (driver)'),
        findsOneWidget,
      );
    });

    testWidgets('los interruptores cambian los controles de los mocks', (
      tester,
    ) async {
      await start(tester);
      harness.router.go('/debug/mocks');
      await tester.pumpAndSettle();

      for (final title in [
        'No network',
        '401 on protected calls',
        '429 on code requests',
        'Session expired',
      ]) {
        await tester.tap(find.text(title));
        await tester.pump();
      }

      expect(harness.controls.forceNetworkError, isTrue);
      expect(harness.controls.force401, isTrue);
      expect(harness.controls.force429, isTrue);
      expect(harness.controls.sessionExpired, isTrue);
    });

    testWidgets('los interruptores de Operación cambian los controles', (
      tester,
    ) async {
      await start(tester);
      harness.router.go('/debug/mocks');
      await tester.pumpAndSettle();

      for (final title in [
        '403 on console routes',
        'Partial console overview',
        'Device registration fails',
      ]) {
        await tester.ensureVisible(find.text(title));
        await tester.tap(find.text(title));
        await tester.pump();
      }

      expect(harness.controls.forceConsole403, isTrue);
      expect(harness.controls.forceConsolePartial, isTrue);
      expect(harness.controls.forceDeviceRegisterFailure, isTrue);
    });

    testWidgets('"Llamar a un endpoint protegido" muestra el efecto del 401', (
      tester,
    ) async {
      await start(tester, signedIn: true);
      harness.router.go('/debug/mocks');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Call a protected endpoint'));
      await tester.pumpAndSettle();
      expect(
        find.text('Last result: Protected call OK: 4 parking lots.'),
        findsOneWidget,
      );

      harness.controls.force401 = true;
      await tester.tap(find.text('Call a protected endpoint'));
      await tester.pumpAndSettle();
      expect(
        find.text('Last result: Failed: UnauthorizedFailure'),
        findsOneWidget,
      );
    });

    testWidgets('"Restablecer datos" recarga la semilla sin cerrar la sesión', (
      tester,
    ) async {
      await start(tester, signedIn: true);
      final world = harness.locator<MockWorld>();
      world.lot(1)!.zones.first.spaces.first.status = 'UNKNOWN';
      world.notifications.subscriptions.clear();
      harness.router.go('/debug/mocks');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reset test data'));
      await tester.pumpAndSettle();

      expect(
        find.text('Last result: Test data reset to the seed.'),
        findsOneWidget,
      );
      expect(world.lot(1)!.count('UNKNOWN'), 3);
      expect(world.notifications.subscriptions, hasLength(3));
      expect(world.iam.refreshTokens, contains('refresh-1'));
    });

    testWidgets('"Expirar la sesión ahora" lleva a /login?reason=expired', (
      tester,
    ) async {
      await start(tester, signedIn: true);
      expect(find.byType(HomePage), findsOneWidget);
      harness.router.go('/debug/mocks');
      await tester.pumpAndSettle();

      // Sin el interruptor, el refresh funciona y la sesión sigue.
      await tester.tap(find.text('Expire the session now'));
      await tester.pumpAndSettle();
      expect(
        find.text('Last result: The session was renewed.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Session expired'));
      await tester.pump();
      await tester.tap(find.text('Expire the session now'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(
        find.text('Your session expired. Sign in again to continue.'),
        findsOneWidget,
      );
      expect(await harness.locator<SessionStore>().read(), isNull);
    });
  });

  group('fuera de debug (release)', () {
    testWidgets('no hay acceso al panel ni ruta', (tester) async {
      await start(tester, debug: false);

      expect(find.byIcon(Icons.bug_report_outlined), findsNothing);

      harness.router.go('/debug/mocks');
      await tester.pumpAndSettle();

      expect(find.byType(MockControlsPage), findsNothing);
      expect(find.byType(LoginPage), findsOneWidget);
    });
  });
}

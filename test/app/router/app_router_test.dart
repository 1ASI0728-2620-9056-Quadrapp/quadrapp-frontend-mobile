// US01, US02, US03: el router decide por el estado de sesión.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/composition/arrival/home_page.dart';
import 'package:quadrapp_mobile/composition/settings/settings_page.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/repositories/session_store.dart';
import 'package:quadrapp_mobile/contexts/iam/iam.dart';
import 'package:quadrapp_mobile/contexts/iam/presentation/pages/login_page.dart';
import 'package:quadrapp_mobile/contexts/iam/presentation/pages/verify_code_page.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

import '../../contexts/iam/support.dart';
import '../../helpers/app_harness.dart';

void main() {
  late AppHarness harness;

  Future<void> start(
    WidgetTester tester, {
    bool signedIn = false,
    Locale? locale,
  }) async {
    tester.view
      ..physicalSize = const Size(400, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    harness = await AppHarness.create(
      seed: signedIn
          ? (locator) => locator<SessionStore>().save(sampleStored())
          : null,
    );
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.app(locale: locale));
    await tester.pumpAndSettle();
  }

  String location() =>
      harness.router.routeInformationProvider.value.uri.toString();

  testWidgets('sin sesión va a /login', (tester) async {
    await start(tester);

    expect(find.byType(LoginPage), findsOneWidget);
    expect(location(), '/login');
  });

  testWidgets('con sesión guardada va a /home sin pedir un código', (
    tester,
  ) async {
    await start(tester, signedIn: true);

    expect(find.byType(HomePage), findsOneWidget);
    expect(location(), '/home');
    expect(find.text('Your arrival'), findsOneWidget);
  });

  testWidgets('con sesión no se puede volver a /login', (tester) async {
    await start(tester, signedIn: true);

    harness.router.go('/login');
    await tester.pumpAndSettle();

    expect(location(), '/home');
  });

  testWidgets('sin sesión, /home redirige a /login', (tester) async {
    await start(tester);

    harness.router.go('/home');
    await tester.pumpAndSettle();

    expect(location(), '/login');
  });

  testWidgets('/login/verify sin un código pedido vuelve a /login', (
    tester,
  ) async {
    await start(tester);

    harness.router.go('/login/verify');
    await tester.pumpAndSettle();

    expect(find.byType(VerifyCodePage), findsNothing);
    expect(location(), '/login');
  });

  testWidgets(
    'sesión expirada con la app en uso: limpia y va a /login?reason=expired',
    (tester) async {
      await start(tester, signedIn: true);
      await harness.values.setString('user.selectedLot', '2');
      expect(find.byType(HomePage), findsOneWidget);

      // El servidor rechaza el refresh: `ExpireSession` avisa y la app limpia.
      await harness.locator<ExpireSession>()(const NoParams());
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
      expect(
        find.text('Your session expired. Sign in again to continue.'),
        findsOneWidget,
      );
      expect(await harness.locator<SessionStore>().read(), isNull);
      expect(await harness.values.getString('user.selectedLot'), isNull);
    },
  );

  testWidgets('el aviso de sesión vencida está en español si se elige', (
    tester,
  ) async {
    await start(tester, signedIn: true, locale: const Locale('es'));

    await harness.locator<ExpireSession>()(const NoParams());
    await tester.pumpAndSettle();

    expect(
      find.text('Tu sesión venció. Inicia sesión de nuevo para continuar.'),
      findsOneWidget,
    );
  });

  testWidgets('flujo completo con los casos de uso reales (mocks)', (
    tester,
  ) async {
    await start(tester);

    // Correo → código.
    await tester.enterText(find.byType(TextFormField), 'conductor@upc.edu.pe');
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();
    expect(find.byType(VerifyCodePage), findsOneWidget);
    expect(
      find.text('We sent a 6-digit code to c•••@upc.edu.pe.'),
      findsOneWidget,
    );

    // Código → /home.
    await tester.enterText(find.byType(QaOtpField), '123456');
    await tester.pumpAndSettle();
    expect(find.byType(HomePage), findsOneWidget);
    expect(location(), '/home');

    // Cerrar sesión (en la cuenta, desde el perfil), con confirmación → /login.
    await tester.tap(find.byTooltip('Account'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Sign out?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out').last);
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    expect(await harness.locator<SessionStore>().read(), isNull);
  });
}

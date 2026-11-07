// Dos experiencias según el rol: cada rol llega a su inicio y no a las rutas
// del otro. El redirect es solo experiencia de usuario (la protección real es
// el 403 del servidor, que los mocks también responden).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/app/router/app_router.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/repositories/session_store.dart';
import 'package:quadrapp_mobile/contexts/iam/iam.dart';
import 'package:quadrapp_mobile/contexts/iam/presentation/pages/login_page.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';

import '../../contexts/iam/support.dart';
import '../../helpers/app_harness.dart';

void main() {
  late AppHarness harness;

  Future<void> start(
    WidgetTester tester, {
    UserRole? role,
    bool debug = false,
  }) async {
    tester.view
      ..physicalSize = const Size(400, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    harness = await AppHarness.create(
      enableGallery: debug,
      enableDebugPanel: debug,
      seed: role == null
          ? null
          : (locator) => locator<SessionStore>().save(sampleStored(role: role)),
    );
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
  }

  String location() =>
      harness.router.routerDelegate.currentConfiguration.uri.path;

  Future<void> goTo(WidgetTester tester, String path) async {
    harness.router.go(path);
    await tester.pumpAndSettle();
  }

  Finder tab(String label) => find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );

  group('inicio por rol', () {
    test('homePathFor: Conductor a /lots, Operación a /ops/shift', () {
      expect(homePathFor(UserRole.driver), homePath);
      expect(homePathFor(UserRole.admin), opsShiftPath);
      expect(homePathFor(UserRole.operator), opsShiftPath);
    });

    testWidgets('un conductor aterriza en /home con la barra de Conductor', (
      tester,
    ) async {
      await start(tester, role: UserRole.driver);

      expect(location(), homePath);
      for (final label in ['Home', 'Zones', 'Forecast', 'Alerts']) {
        expect(tab(label), findsOneWidget);
      }
      for (final label in ['Gates', 'Analytics', 'More']) {
        expect(tab(label), findsNothing);
      }
    });

    for (final role in [UserRole.admin, UserRole.operator]) {
      testWidgets('${role.name}: aterriza en /ops/shift con la barra de '
          'Operación', (tester) async {
        await start(tester, role: role);

        expect(location(), opsShiftPath);
        // La misma barra para los dos roles, como el diseño.
        for (final label in ['Home', 'Zones', 'Gates', 'Analytics', 'More']) {
          expect(tab(label), findsOneWidget);
        }
        for (final label in ['Forecast', 'Alerts']) {
          expect(tab(label), findsNothing);
        }
      });
    }

    testWidgets('en español las pestañas de Operación son Inicio, Zonas, '
        'Accesos, Analítica y Más', (tester) async {
      tester.view
        ..physicalSize = const Size(400, 900)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      harness = await AppHarness.create(
        seed: (locator) => locator<SessionStore>().save(
          sampleStored(role: UserRole.admin),
        ),
      );
      addTearDown(harness.dispose);
      await tester.pumpWidget(harness.app(locale: const Locale('es')));
      await tester.pumpAndSettle();

      for (final label in ['Inicio', 'Zonas', 'Accesos', 'Analítica', 'Más']) {
        expect(tab(label), findsOneWidget);
      }
    });
  });

  group('cada rol no llega a las rutas del otro', () {
    testWidgets(
      'un conductor es llevado a /home desde las rutas de Operación',
      (tester) async {
        await start(tester, role: UserRole.driver);

        for (final path in [
          opsPath,
          opsShiftPath,
          opsZonesPath,
          '$opsZonesPath/1',
          opsAccessesPath,
          opsAnalyticsPath,
          opsMorePath,
          opsDevicesPath,
          opsAccountPath,
        ]) {
          await goTo(tester, path);
          expect(location(), homePath, reason: path);
          expect(tab('Forecast'), findsOneWidget, reason: path);
        }
      },
    );

    for (final role in [UserRole.admin, UserRole.operator]) {
      testWidgets('${role.name} es llevado a /ops/shift desde las rutas del '
          'Conductor', (tester) async {
        await start(tester, role: role);

        for (final path in [
          homePath,
          zonesPath,
          '$zonesPath/1',
          forecastPath,
          alertsPath,
          accountPath,
        ]) {
          await goTo(tester, path);
          expect(location(), opsShiftPath, reason: path);
          expect(tab('Analytics'), findsOneWidget, reason: path);
        }
      });
    }

    testWidgets('sin sesión, las rutas de Operación llevan a /login', (
      tester,
    ) async {
      await start(tester);

      await goTo(tester, opsShiftPath);

      expect(location(), loginPath);
      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('la galería y el panel de depuración los abre cualquier rol, '
        'sin barra', (tester) async {
      await start(tester, role: UserRole.admin, debug: true);

      for (final path in ['/gallery', '/debug/mocks']) {
        await goTo(tester, path);
        expect(location(), path);
        expect(find.byType(NavigationBar), findsNothing);
      }
    });
  });

  group('cada shell conserva su estado y su propia barra', () {
    testWidgets('Operación: las cinco pestañas navegan a sus rutas', (
      tester,
    ) async {
      await start(tester, role: UserRole.admin);

      for (final (label, path) in [
        ('Zones', opsZonesPath),
        ('Gates', opsAccessesPath),
        ('Analytics', opsAnalyticsPath),
        ('More', opsMorePath),
        ('Home', opsShiftPath),
      ]) {
        await tester.tap(tab(label));
        await tester.pumpAndSettle();
        expect(location(), path);
        expect(find.byType(NavigationBar), findsOneWidget);
      }
    });

    testWidgets(
      'La cuenta de Operación (avatar) muestra el rol Administrator y cierra '
      'la sesión',
      (tester) async {
        await start(tester, role: UserRole.admin);

        await tester.tap(find.byTooltip('Account'));
        await tester.pumpAndSettle();
        // La cuenta se apila sobre la consola, sin barra inferior.
        expect(find.byType(NavigationBar), findsNothing);
        expect(find.text('Administrator'), findsOneWidget);

        await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(FilledButton, 'Sign out').last);
        await tester.pumpAndSettle();

        expect(location(), loginPath);
        expect(await harness.locator<SessionStore>().read(), isNull);
      },
    );

    testWidgets(
      'La cuenta de Operación (avatar) muestra Operator para ese rol',
      (
        tester,
      ) async {
        await start(tester, role: UserRole.operator);

        await tester.tap(find.byTooltip('Account'));
        await tester.pumpAndSettle();

        expect(find.text('Operator'), findsOneWidget);
      },
    );
  });

  group('el login lleva a cada rol a su experiencia', () {
    Future<void> signIn(WidgetTester tester, String email) async {
      await tester.enterText(find.byType(TextFormField), email);
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(QaOtpField), '123456');
      await tester.pumpAndSettle();
      // La cuenta regresiva de reenvío de la pantalla anterior termina.
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    }

    testWidgets('administrador@upc.edu.pe entra a /ops/shift', (tester) async {
      await start(tester);

      await signIn(tester, 'administrador@upc.edu.pe');

      expect(location(), opsShiftPath);
      expect(tab('Analytics'), findsOneWidget);
    });

    testWidgets('conductor@upc.edu.pe entra a /home', (tester) async {
      await start(tester);

      await signIn(tester, 'conductor@upc.edu.pe');

      expect(location(), homePath);
      expect(tab('Home'), findsOneWidget);
    });
  });
}

// docs/02 y docs/05: la barra inferior y el shell de las pestañas.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quadrapp_mobile/app/router/app_router.dart';
import 'package:quadrapp_mobile/app/shell/app_shell.dart';
import 'package:quadrapp_mobile/app/shell/shell_tabs.dart';
import 'package:quadrapp_mobile/app/theme/app_theme.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/repositories/session_store.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';

import '../../contexts/iam/support.dart';
import '../../helpers/app_harness.dart';

/// Un contador por pestaña (para comprobar que conservan su estado) con una
/// subruta y una lista que sube al inicio al volver a tocar la pestaña.
class _TabPage extends StatefulWidget {
  const _TabPage(this.index);

  final int index;

  @override
  State<_TabPage> createState() => _TabPageState();
}

class _TabPageState extends State<_TabPage> {
  final ScrollController _scroll = ScrollController();
  int taps = 0;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return QaScrollToTopOnReselect(
      tabIndex: widget.index,
      controller: _scroll,
      child: Scaffold(
        body: ListView(
          controller: _scroll,
          children: [
            TextButton(
              onPressed: () => setState(() => taps++),
              child: Text('tab ${widget.index} taps: $taps'),
            ),
            TextButton(
              onPressed: () => context.push('/t${widget.index}/detail'),
              child: const Text('open detail'),
            ),
            for (var i = 0; i < 40; i++) const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}

GoRouter _router() => GoRouter(
  initialLocation: '/t0',
  routes: [
    StatefulShellRoute(
      builder: (context, state, shell) => shell,
      navigatorContainerBuilder: (context, shell, children) => AppShell(
        navigationShell: shell,
        tabs: AppTab.driver,
        children: children,
      ),
      branches: [
        for (var i = 0; i < AppTab.driver.length; i++)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/t$i',
                builder: (context, state) => _TabPage(i),
                routes: [
                  GoRoute(
                    path: 'detail',
                    builder: (context, state) =>
                        Scaffold(body: Text('detail $i')),
                  ),
                ],
              ),
            ],
          ),
      ],
    ),
  ],
);

Future<GoRouter> _pump(
  WidgetTester tester, {
  Brightness brightness = Brightness.light,
  Locale locale = const Locale('en'),
  double textScale = 1,
  Size size = const Size(360, 800),
}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.accessibilityFeaturesTestValue =
      const FakeAccessibilityFeatures(disableAnimations: true);
  addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
  final router = _router();
  addTearDown(router.dispose);
  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
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
    ),
  );
  await tester.pumpAndSettle();
  return router;
}

String _location(GoRouter router) =>
    router.routerDelegate.currentConfiguration.uri.toString();

void main() {
  group('barra inferior', () {
    testWidgets('cuatro destinos con la etiqueta siempre visible, en inglés', (
      tester,
    ) async {
      await _pump(tester);

      expect(find.byType(NavigationBar), findsOneWidget);
      for (final label in ['Home', 'Zones', 'Forecast', 'Alerts']) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('en español: Inicio, Zonas, Predicción, Alertas', (
      tester,
    ) async {
      await _pump(tester, locale: const Locale('es'));

      for (final label in ['Inicio', 'Zonas', 'Predicción', 'Alertas']) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('la seleccionada usa el ícono relleno y las demás, el '
        'delineado', (tester) async {
      await _pump(tester);

      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.home_outlined), findsNothing);
      expect(find.byIcon(Icons.map_outlined), findsOneWidget);
      expect(find.byIcon(Icons.map), findsNothing);

      await tester.tap(find.text('Zones'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.map), findsOneWidget);
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    });

    testWidgets('la etiqueta seleccionada va en semibold y las demás en '
        'regular', (tester) async {
      await _pump(tester);

      FontWeight? weight(String label) =>
          tester.widget<Text>(find.text(label)).style?.fontWeight;
      // El estilo viene del tema: se resuelve con el estado de cada destino.
      final theme = Theme.of(tester.element(find.byType(NavigationBar)));
      final style = theme.navigationBarTheme.labelTextStyle!;
      expect(
        style.resolve({WidgetState.selected})!.fontWeight,
        FontWeight.w600,
      );
      expect(style.resolve({})!.fontWeight, FontWeight.w400);
      expect(weight('Home'), anyOf(isNull, FontWeight.w600));
    });

    testWidgets('el borde superior es de 1 dp y no hay sombra', (tester) async {
      await _pump(tester);

      final theme = Theme.of(tester.element(find.byType(NavigationBar)));
      expect(theme.navigationBarTheme.elevation, 0);
      expect(theme.navigationBarTheme.shadowColor, Colors.transparent);
      final border = tester
          .widgetList<DecoratedBox>(
            find.ancestor(
              of: find.byType(NavigationBar),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((box) => box.decoration)
          .whereType<BoxDecoration>()
          .map((decoration) => decoration.border)
          .whereType<Border>()
          .first;
      expect(border.top.width, 1);
    });

    for (final (name, brightness, scale, size) in [
      ('claro 360×800', Brightness.light, 1.0, const Size(360, 800)),
      ('oscuro 360×800', Brightness.dark, 1.0, const Size(360, 800)),
      ('claro con texto al 200 %', Brightness.light, 2.0, const Size(360, 640)),
      ('oscuro con texto al 200 %', Brightness.dark, 2.0, const Size(360, 640)),
    ]) {
      testWidgets('$name: guías de accesibilidad y sin desbordes', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await _pump(
          tester,
          brightness: brightness,
          textScale: scale,
          size: size,
        );

        expect(tester.takeException(), isNull);
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }

    testWidgets('cada destino mide al menos 48 dp', (tester) async {
      await _pump(tester);

      final destinations = find.byType(NavigationDestination);
      expect(destinations, findsNWidgets(4));
      for (final element in destinations.evaluate()) {
        final size = tester.getSize(
          find.byElementPredicate((e) => e == element),
        );
        expect(size.height, greaterThanOrEqualTo(48));
        expect(size.width, greaterThanOrEqualTo(48));
      }
    });

    testWidgets('semántica: pestaña seleccionada y posición (1 de 4)', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester);

      final home = tester.getSemantics(
        find
            .descendant(
              of: find.byType(NavigationDestination).first,
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(home, isNotNull);
      final labelled = find.bySemanticsLabel(RegExp('Tab 1 of 4'));
      expect(labelled, findsWidgets);
      expect(find.bySemanticsLabel(RegExp('Tab 4 of 4')), findsWidgets);
      expect(
        tester.getSemantics(labelled.first),
        matchesSemantics(
          label: 'Home\nTab 1 of 4',
          isSelected: true,
          hasSelectedState: true,
          isButton: true,
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true,
          hasEnabledState: true,
          isEnabled: true,
        ),
      );
      handle.dispose();
    });
  });

  group('shell', () {
    testWidgets('cada pestaña conserva su estado al cambiar', (tester) async {
      await _pump(tester);
      await tester.tap(find.text('tab 0 taps: 0'));
      await tester.pump();
      await tester.tap(find.text('tab 0 taps: 1'));
      await tester.pump();
      expect(find.text('tab 0 taps: 2'), findsOneWidget);

      await tester.tap(find.text('Alerts'));
      await tester.pumpAndSettle();
      expect(find.text('tab 3 taps: 0'), findsOneWidget);
      expect(find.text('tab 0 taps: 2'), findsNothing);

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.text('tab 0 taps: 2'), findsOneWidget);
    });

    testWidgets('tocar la pestaña activa vuelve a su raíz', (tester) async {
      final router = await _pump(tester);
      await tester.tap(find.text('open detail'));
      await tester.pumpAndSettle();
      expect(find.text('detail 0'), findsOneWidget);
      // La barra sigue en las subrutas.
      expect(find.byType(NavigationBar), findsOneWidget);

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      expect(_location(router), '/t0');
      expect(find.text('detail 0'), findsNothing);
    });

    testWidgets('tocar la pestaña activa sube al inicio de la lista', (
      tester,
    ) async {
      await _pump(tester);
      await tester.drag(find.byType(ListView).first, const Offset(0, -900));
      await tester.pump();
      final scrollable = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      expect(scrollable.position.pixels, greaterThan(0));

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      expect(scrollable.position.pixels, 0);
    });

    testWidgets('tocar otra pestaña no sube la lista de la primera', (
      tester,
    ) async {
      await _pump(tester);
      await tester.drag(find.byType(ListView).first, const Offset(0, -900));
      await tester.pump();
      final scrollable = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );

      await tester.tap(find.text('Zones'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      expect(scrollable.position.pixels, greaterThan(0));
    });

    testWidgets('atrás en la raíz de otra pestaña lleva a Inicio', (
      tester,
    ) async {
      final router = await _pump(tester);
      await tester.tap(find.text('Alerts'));
      await tester.pumpAndSettle();
      expect(_location(router), '/t3');

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(_location(router), '/t0');
    });

    testWidgets('el cambio de pestaña es un fade de 200 ms', (tester) async {
      tester.platformDispatcher.clearAccessibilityFeaturesTestValue();
      await _pump(tester);
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures();
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Zones'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final opacity = tester
          .widgetList<FadeTransition>(find.byType(FadeTransition))
          .map((fade) => fade.opacity.value)
          .where((value) => value > 0 && value < 1);
      expect(opacity, isNotEmpty);
      await tester.pumpAndSettle();
    });
  });

  group('rutas de la app', () {
    late AppHarness harness;

    Future<void> start(
      WidgetTester tester, {
      bool signedIn = true,
      bool debug = false,
    }) async {
      tester.view
        ..physicalSize = const Size(400, 900)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      harness = await AppHarness.create(
        enableGallery: debug,
        enableDebugPanel: debug,
        seed: signedIn
            ? (locator) => locator<SessionStore>().save(sampleStored())
            : null,
      );
      addTearDown(harness.dispose);
      await tester.pumpWidget(harness.app());
      await tester.pumpAndSettle();
    }

    testWidgets('con sesión hay barra en las cuatro pestañas', (tester) async {
      await start(tester);

      for (final (label, path) in [
        ('Zones', zonesPath),
        ('Forecast', forecastPath),
        ('Alerts', alertsPath),
        ('Home', homePath),
      ]) {
        await tester.tap(
          find.descendant(
            of: find.byType(NavigationBar),
            matching: find.text(label),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          harness.router.routeInformationProvider.value.uri.path,
          path,
        );
        expect(find.byType(NavigationBar), findsOneWidget);
      }
    });

    testWidgets('sin barra en /login ni en /login/verify', (tester) async {
      await start(tester, signedIn: false);

      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('sin barra en /gallery ni en /debug/mocks', (tester) async {
      await start(tester, signedIn: false, debug: true);

      for (final path in ['/gallery', '/debug/mocks']) {
        harness.router.go(path);
        await tester.pumpAndSettle();
        expect(find.byType(NavigationBar), findsNothing, reason: path);
      }
    });
  });
}

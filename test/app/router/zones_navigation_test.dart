// US06, US08: Zonas → pabellón → nivel con la app completa y los datos de
// prueba (docs/07): el pabellón con varios niveles abre sus niveles; el de un
// solo nivel, directo el mapa; «atrás» deshace lo que se abrió.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:quadrapp_mobile/composition/zones/level_page.dart';
import 'package:quadrapp_mobile/composition/zones/zone_page.dart';
import 'package:quadrapp_mobile/composition/zones/zones_tab_page.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/repositories/session_store.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/repositories/selected_lot_store.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

import '../../contexts/iam/support.dart';
import '../../helpers/app_harness.dart';

void main() {
  late AppHarness harness;

  Future<void> start(WidgetTester tester, String path) async {
    tester.view
      ..physicalSize = const Size(400, 1400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    harness = await AppHarness.create(
      seed: (locator) async {
        await locator<SessionStore>().save(sampleStored());
        await locator<SelectedLotStore>().save(const LotId(1));
      },
    );
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    harness.router.go(path);
    await tester.pumpAndSettle();
  }

  // Lo que se abre con `push` no cambia la dirección base: se lee la de la
  // última pantalla.
  String location() {
    final configuration = harness.router.routerDelegate.currentConfiguration;
    final last = configuration.last;
    return last is ImperativeRouteMatch
        ? last.matches.uri.toString()
        : configuration.uri.toString();
  }

  Future<void> goBack(WidgetTester tester) async {
    await tester.tap(find.byType(IconButton).first);
    await tester.pumpAndSettle();
  }

  testWidgets('Zonas lista los pabellones de la sede elegida', (tester) async {
    await start(tester, '/zones');

    expect(find.byType(ZonesTabPage), findsOneWidget);
    expect(find.text('Monterrico'), findsOneWidget);
    for (final name in ['Pabellón A', 'Pabellón B', 'Pabellón C']) {
      expect(find.text(name), findsOneWidget);
    }
    expect(find.text('Edificios A–C'), findsOneWidget);
  });

  testWidgets(
    'un pabellón con varios niveles abre sus niveles, y de ahí el mapa',
    (
      tester,
    ) async {
      await start(tester, '/zones');

      await tester.tap(find.text('Pabellón A'));
      await tester.pumpAndSettle();
      expect(find.byType(ZonePage), findsOneWidget);
      expect(location(), '/zones/11');
      expect(find.text('Sótano 2'), findsOneWidget);
      expect(find.text('Sótano 1'), findsOneWidget);

      await tester.tap(find.text('Sótano 2'));
      await tester.pumpAndSettle();
      expect(find.byType(LevelPage), findsOneWidget);
      expect(location(), '/zones/11/levels/111');
      expect(find.byType(QaSpaceMap), findsOneWidget);

      await goBack(tester);
      expect(location(), '/zones/11');
      await goBack(tester);
      expect(location(), '/zones');
      expect(find.byType(ZonesTabPage), findsOneWidget);
    },
  );

  testWidgets('un pabellón de un solo nivel abre directo el nivel', (
    tester,
  ) async {
    await start(tester, '/zones');

    await tester.tap(find.text('Pabellón C'));
    await tester.pumpAndSettle();
    expect(find.byType(LevelPage), findsOneWidget);
    expect(location(), '/zones/13/levels/131');

    await goBack(tester);
    expect(location(), '/zones');
  });

  testWidgets('un enlace directo a un nivel carga la sede y vuelve a Zonas', (
    tester,
  ) async {
    await start(tester, '/zones/11/levels/111');

    expect(find.byType(LevelPage), findsOneWidget);
    expect(find.text('Sótano 2'), findsWidgets);
    expect(find.byType(QaSpaceMap), findsOneWidget);

    await goBack(tester);
    expect(find.byType(ZonesTabPage), findsOneWidget);
  });

  testWidgets('un pabellón que no existe lo dice y ofrece volver', (
    tester,
  ) async {
    await start(tester, '/zones/abc');

    expect(find.text("We couldn't find this pavilion"), findsOneWidget);
    await tester.tap(find.text('Back to parking'));
    await tester.pumpAndSettle();
    expect(find.byType(ZonesTabPage), findsOneWidget);
  });

  testWidgets('cambiar de sede en Zonas muestra los pabellones de la nueva', (
    tester,
  ) async {
    await start(tester, '/zones');

    await tester.tap(find.text('Monterrico'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Villa'));
    await tester.pumpAndSettle();

    expect(find.text('Pabellón D'), findsOneWidget);
    expect(find.text('Explanada'), findsOneWidget);
  });

  testWidgets('San Miguel, sin distribución, se presenta sin disponibilidad', (
    tester,
  ) async {
    await start(tester, '/zones');

    await tester.tap(find.text('Monterrico'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('San Miguel'));
    await tester.pumpAndSettle();

    expect(find.textContaining('No current data'), findsOneWidget);
    expect(find.text('Pabellón A'), findsNothing);
  });
}

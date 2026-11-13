// US17: el administrador de universidad edita y publica la distribución; el
// operador no la edita (el servidor y los mocks responden 403 igual).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/app/mocks/mock_world.dart';
import 'package:quadrapp_mobile/app/router/app_router.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/repositories/session_store.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/user_role.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/repositories/selected_lot_store.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

import '../../contexts/iam/support.dart';
import '../../helpers/app_harness.dart';

void main() {
  late AppHarness harness;

  Future<void> start(WidgetTester tester, UserRole role) async {
    tester.view
      ..physicalSize = const Size(400, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    harness = await AppHarness.create(
      seed: (locator) async {
        await locator<SessionStore>().save(sampleStored(role: role));
        await locator<SelectedLotStore>().save(const LotId(1));
      },
    );
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    harness.router.go(opsZonesPath);
    await tester.pumpAndSettle();
  }

  String location() =>
      harness.router.routerDelegate.currentConfiguration.uri.path;

  testWidgets('el administrador añade una zona, publica y Estacionamientos '
      'la muestra', (tester) async {
    await start(tester, UserRole.admin);

    await tester.ensureVisible(find.text('Manage zones and spaces'));
    await tester.tap(find.text('Manage zones and spaces'));
    await tester.pumpAndSettle();
    expect(find.text('Version 4 published'), findsOneWidget);

    await tester.tap(find.text('Add zone'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Zona Este');
    await tester.enterText(find.byType(TextFormField).last, '5');
    await tester.tap(find.text('Add to draft'));
    await tester.pumpAndSettle();

    expect(find.text('Draft · version 5'), findsOneWidget);
    expect(find.text('E-01'), findsOneWidget);

    await tester.ensureVisible(find.text('Publish version 5'));
    await tester.tap(find.text('Publish version 5'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Publish'));
    await tester.pumpAndSettle();

    expect(find.text('Version 5 published'), findsWidgets);
    final lot = harness.locator<MockWorld>().lot(1)!;
    expect(lot.layoutVersion, 5);
    expect(lot.zones.last.name, 'Zona Este');
    // Nuevos sin sensor: desconocidos, nunca libres.
    expect(lot.zones.last.spaces.every((s) => s.status == 'UNKNOWN'), isTrue);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Zona Este'), findsOneWidget);
  });

  testWidgets('el operador no ve «Gestionar» y la ruta lo devuelve', (
    tester,
  ) async {
    await start(tester, UserRole.operator);

    expect(find.text('Manage zones and spaces'), findsNothing);

    harness.router.go(opsLayoutPath);
    await tester.pumpAndSettle();
    expect(location(), opsZonesPath);
  });
}

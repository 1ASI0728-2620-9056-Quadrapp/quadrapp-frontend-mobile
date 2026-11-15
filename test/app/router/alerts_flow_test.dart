// US23, US24, US33: Alertas con la app completa y los datos de prueba
// (docs/07): los cambios llegan al servidor simulado, el permiso de
// notificaciones se pide al activarlas y un servidor que falla no deja el
// interruptor mentiroso.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/app/mocks/mock_world.dart';
import 'package:quadrapp_mobile/app/mocks/notifications/stub_push_gateway.dart';
import 'package:quadrapp_mobile/composition/alerts/alerts_tab_page.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/repositories/session_store.dart';

import '../../contexts/iam/support.dart';
import '../../helpers/app_harness.dart';

void main() {
  late AppHarness harness;

  MockWorld world() => harness.locator<MockWorld>();

  Future<void> start(WidgetTester tester) async {
    tester.view
      ..physicalSize = const Size(400, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    harness = await AppHarness.create(
      seed: (locator) => locator<SessionStore>().save(sampleStored()),
    );
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    harness.router.go('/alerts');
    await tester.pumpAndSettle();
  }

  testWidgets('muestra las preferencias y las tres franjas de prueba', (
    tester,
  ) async {
    await start(tester);

    expect(find.byType(AlertsTabPage), findsOneWidget);
    expect(find.text('Alerts and preferences'), findsWidgets);
    expect(find.text('Monterrico'), findsNWidgets(2));
    expect(find.text('San Isidro'), findsOneWidget);
    expect(find.text('Paused'), findsOneWidget);
    final switches = tester
        .widgetList<Switch>(find.byType(Switch))
        .map((w) => w.value)
        .toList();
    // General, saturación, baja, datos, eventos y las tres franjas.
    expect(switches, [true, true, false, true, false, true, true, false]);
  });

  testWidgets('encender una alerta llega al servidor', (tester) async {
    await start(tester);
    expect(world().notifications.eventAlerts, isFalse);

    await tester.tap(find.text('Events change things'));
    await tester.pumpAndSettle();

    expect(world().notifications.eventAlerts, isTrue);
    // Lo demás no cambió: el PUT lleva todos los campos.
    expect(world().notifications.saturationAlerts, isTrue);
    expect(world().notifications.locale, 'es-419');
  });

  testWidgets('apagar las notificaciones desactiva las alertas', (
    tester,
  ) async {
    await start(tester);

    await tester.tap(find.text('Receive notifications'));
    await tester.pumpAndSettle();

    expect(world().notifications.pushEnabled, isFalse);
    expect(tester.widget<Switch>(find.byType(Switch).at(1)).onChanged, isNull);
    expect(
      find.text('Turn notifications on to choose which alerts you get.'),
      findsOneWidget,
    );
  });

  testWidgets('activarlas pide el permiso y registra el teléfono', (
    tester,
  ) async {
    await start(tester);
    await tester.tap(find.text('Receive notifications'));
    await tester.pumpAndSettle();
    expect(world().notifications.deviceTokens, isEmpty);

    await tester.tap(find.text('Receive notifications'));
    await tester.pumpAndSettle();

    expect(world().notifications.pushEnabled, isTrue);
    expect(world().notifications.deviceTokens, {StubPushGateway.mockToken});
  });

  testWidgets('si el conductor niega el permiso, no se activan y se explica', (
    tester,
  ) async {
    await start(tester);
    harness.controls.denyPushPermission = true;
    await tester.tap(find.text('Receive notifications'));
    await tester.pumpAndSettle();
    expect(world().notifications.pushEnabled, isFalse);

    await tester.tap(find.text('Receive notifications'));
    await tester.pumpAndSettle();

    expect(world().notifications.pushEnabled, isFalse);
    expect(
      find.text("We can't alert you without the notifications permission."),
      findsOneWidget,
    );
  });

  testWidgets('pausar y reactivar una franja la conserva', (tester) async {
    await start(tester);

    await tester.tap(find.byType(Switch).at(5));
    await tester.pumpAndSettle();
    expect(world().notifications.subscriptions.first.active, isFalse);
    expect(find.text('Paused'), findsNWidgets(2));
    expect(world().notifications.subscriptions, hasLength(3));

    await tester.tap(find.byType(Switch).at(5));
    await tester.pumpAndSettle();
    expect(world().notifications.subscriptions.first.active, isTrue);
    expect(find.text('Paused'), findsOneWidget);
  });

  testWidgets('eliminar una franja es definitivo y conserva las demás', (
    tester,
  ) async {
    await start(tester);

    await tester.tap(find.byTooltip(RegExp('Delete the slot for San Isidro')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(
      world().notifications.subscriptions.map((s) => s.id),
      [1, 3],
    );
    expect(find.text('San Isidro'), findsNothing);
    expect(find.text('Time slot deleted'), findsOneWidget);
  });

  testWidgets('un servidor que falla deja el interruptor como estaba', (
    tester,
  ) async {
    await start(tester);
    harness.controls.forceNetworkError = true;

    await tester.tap(find.text('Events change things'));
    await tester.pumpAndSettle();

    expect(world().notifications.eventAlerts, isFalse);
    expect(tester.widget<Switch>(find.byType(Switch).at(4)).value, isFalse);
    expect(
      find.text("We couldn't save your preferences. Try again."),
      findsOneWidget,
    );
  });
}

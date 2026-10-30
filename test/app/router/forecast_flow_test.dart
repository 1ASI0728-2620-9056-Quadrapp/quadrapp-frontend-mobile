// US09, US10, US11, US12: Predicción con la app completa y los datos de prueba
// (docs/07): las cifras de cada horizonte, su detalle, el horizonte faltante
// que se prueba desde el panel de mocks y el cambio de sede.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/composition/forecast/forecast_tab_page.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/repositories/session_store.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/repositories/selected_lot_store.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

import '../../contexts/iam/support.dart';
import '../../helpers/app_harness.dart';

void main() {
  late AppHarness harness;

  Future<void> start(
    WidgetTester tester, {
    int lot = 1,
    Set<int> missing = const {},
  }) async {
    tester.view
      ..physicalSize = const Size(400, 1800)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    harness = await AppHarness.create(
      seed: (locator) async {
        await locator<SessionStore>().save(sampleStored());
        await locator<SelectedLotStore>().save(LotId(lot));
      },
    );
    addTearDown(harness.dispose);
    harness.controls.missingForecastHorizons = missing;
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    harness.router.go('/forecast');
    await tester.pumpAndSettle();
  }

  testWidgets('muestra los cuatro horizontes de la sede elegida', (
    tester,
  ) async {
    await start(tester);

    expect(find.byType(ForecastTabPage), findsOneWidget);
    expect(find.text('Monterrico'), findsOneWidget);
    expect(find.textContaining('You arrive in'), findsOneWidget);
    for (final minutes in [15, 30, 45, 60]) {
      expect(find.text('$minutes min'), findsOneWidget);
    }
    expect(find.textContaining('Confidence:'), findsWidgets);
    expect(find.textContaining('Generated at'), findsOneWidget);
  });

  testWidgets('un horizonte sin pronóstico se indica y no se inventa', (
    tester,
  ) async {
    await start(tester, missing: {45});

    expect(find.text('No forecast for this time'), findsOneWidget);
    expect(
      find.text('Some forecasts are missing. Showing the ones we have.'),
      findsOneWidget,
    );
  });

  testWidgets('el detalle del horizonte dice la ocupación y la confianza', (
    tester,
  ) async {
    await start(tester);

    await tester.tap(find.text('30 min'));
    await tester.pumpAndSettle();

    expect(find.text('Forecast in 30 min'), findsOneWidget);
    expect(find.text('Expected occupancy'), findsOneWidget);
    expect(find.text('Generated'), findsOneWidget);
    expect(find.textContaining('Confidence:'), findsWidgets);
  });

  testWidgets('San Isidro, llena, prevé la saturación', (tester) async {
    await start(tester, lot: 2);

    await tester.tap(find.text('60 min'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Expected to fill up at'), findsOneWidget);
  });

  testWidgets('cambiar de sede muestra la predicción de la nueva', (
    tester,
  ) async {
    await start(tester);

    await tester.tap(find.text('Monterrico'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Villa'));
    await tester.pumpAndSettle();

    expect(find.text('Villa'), findsOneWidget);
    expect(find.text('15 min'), findsOneWidget);
    expect(find.textContaining('Generated at'), findsOneWidget);
  });

  testWidgets('San Miguel, sin distribución, se presenta sin información', (
    tester,
  ) async {
    await start(tester, lot: 3);

    expect(find.textContaining('No current data'), findsOneWidget);
    expect(find.text('15 min'), findsNothing);
  });

  testWidgets('el calendario de la barra abre «¿Cuándo llegas?»', (
    tester,
  ) async {
    await start(tester);

    await tester.tap(find.byTooltip('Choose your arrival time'));
    await tester.pumpAndSettle();

    expect(find.text('When do you arrive?'), findsWidgets);
  });
}

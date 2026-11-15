import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';

import '../../../helpers/pump_screen.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    Widget bar, {
    double textScale = 1,
    Brightness brightness = Brightness.light,
  }) => pumpScreen(
    tester,
    Scaffold(body: Column(children: [bar])),
    textScale: textScale,
    brightness: brightness,
  );

  group('QaTopBar de pestaña', () {
    testWidgets('lleva el logo, Quadrapp, el título y la acción', (
      tester,
    ) async {
      var taps = 0;
      await pump(
        tester,
        QaTopBar(
          title: 'Your arrival',
          action: QaTopBarAction(
            icon: Icons.account_circle_outlined,
            label: 'Account',
            onPressed: () => taps++,
          ),
        ),
      );

      expect(find.byType(QaBrandMark), findsOneWidget);
      expect(find.text('Quadrapp'), findsOneWidget);
      expect(find.text('Your arrival'), findsOneWidget);
      await tester.tap(find.byTooltip('Account'));
      expect(taps, 1);
    });

    testWidgets('el título es un encabezado y la acción mide 48 dp', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        QaTopBar(
          title: 'Forecast',
          action: QaTopBarAction(
            icon: Icons.calendar_month_outlined,
            label: 'Pick a time',
            onPressed: () {},
          ),
        ),
      );

      expect(
        tester.getSemantics(find.text('Forecast')),
        matchesSemantics(label: 'Forecast', isHeader: true),
      );
      final size = tester.getSize(find.byType(IconButton));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
      handle.dispose();
    });

    testWidgets('con el texto al 200 % se oculta el nombre de la marca y '
        'el logo se queda', (tester) async {
      await pump(
        tester,
        const QaTopBar(title: 'Alerts and preferences'),
        textScale: 2,
      );

      expect(find.text('Quadrapp'), findsNothing);
      expect(find.byType(QaBrandMark), findsOneWidget);
      expect(find.text('Alerts and preferences'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sin acción no deja un hueco y no hay desbordes', (
      tester,
    ) async {
      await pump(tester, const QaTopBar(title: 'Alerts and preferences'));

      expect(find.byType(IconButton), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('QaTopBar con volver', () {
    testWidgets('lleva la flecha de volver con su etiqueta y el título', (
      tester,
    ) async {
      var back = 0;
      await pump(
        tester,
        QaTopBar(title: 'Account', onBack: () => back++, backLabel: 'Back'),
      );

      expect(find.text('Quadrapp'), findsNothing);
      expect(find.text('Account'), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      expect(back, 1);
    });
  });

  testWidgets('el logo no se anuncia: el nombre va al lado, como texto', (
    tester,
  ) async {
    await pump(tester, const QaTopBar(title: 'Forecast'));

    expect(
      find.descendant(
        of: find.byType(QaBrandMark),
        matching: find.byType(ExcludeSemantics),
      ),
      findsWidgets,
    );
  });
}

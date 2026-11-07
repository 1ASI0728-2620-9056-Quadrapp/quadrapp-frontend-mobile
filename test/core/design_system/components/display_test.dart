import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('QaStatusChip', () {
    testWidgets('muestra el texto y un ícono distinto por tono', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        const Wrap(
          children: [
            QaStatusChip(tone: QaTone.free, label: 'Free'),
            QaStatusChip(tone: QaTone.limited, label: 'Limited'),
            QaStatusChip(tone: QaTone.full, label: 'Occupied'),
            QaStatusChip(tone: QaTone.unknown, label: 'No data'),
          ],
        ),
      );

      expect(find.text('Free'), findsOneWidget);
      expect(find.text('No data'), findsOneWidget);
      for (final tone in [
        QaTone.free,
        QaTone.limited,
        QaTone.full,
        QaTone.unknown,
      ]) {
        expect(find.byIcon(QaStatusChip.iconOf(tone)), findsOneWidget);
      }
    });

    testWidgets('sin ícono solo lleva el texto', (tester) async {
      await pumpInApp(
        tester,
        const QaStatusChip(tone: QaTone.free, label: 'Good', showIcon: false),
      );

      expect(find.text('Good'), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('lo lee como una sola etiqueta', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpInApp(
        tester,
        const QaStatusChip(tone: QaTone.unknown, label: 'No data'),
      );

      expect(find.bySemanticsLabel('No data'), findsOneWidget);
      handle.dispose();
    });
  });

  group('QaConfidenceMeter', () {
    testWidgets('confianza baja muestra la nota', (tester) async {
      await pumpInApp(
        tester,
        const QaConfidenceMeter(
          level: QaConfidenceLevel.low,
          label: 'Low confidence',
          note: 'Estimate based on limited data',
        ),
      );

      expect(find.text('Low confidence'), findsOneWidget);
      expect(find.text('Estimate based on limited data'), findsOneWidget);
    });

    testWidgets('semántica une el nivel y la nota', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpInApp(
        tester,
        const QaConfidenceMeter(
          level: QaConfidenceLevel.low,
          label: 'Low confidence',
          note: 'Estimate based on limited data',
        ),
      );

      expect(
        find.bySemanticsLabel('Low confidence. Estimate based on limited data'),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('QaFreshnessLabel', () {
    testWidgets('desactualizado usa ícono de aviso y texto', (tester) async {
      await pumpInApp(
        tester,
        const QaFreshnessLabel(label: 'No new data since 8:42', isStale: true),
      );

      expect(find.text('No new data since 8:42'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('vigente usa el ícono de reloj', (tester) async {
      await pumpInApp(
        tester,
        const QaFreshnessLabel(label: 'Updated 20 s ago'),
      );

      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });
  });

  group('QaBanner', () {
    testWidgets('muestra el mensaje y la acción', (tester) async {
      var retried = false;
      await pumpInApp(
        tester,
        QaBanner(
          kind: QaBannerKind.offline,
          message: 'You are offline.',
          actionLabel: 'Retry',
          onAction: () => retried = true,
        ),
      );

      await tester.tap(find.text('Retry'));

      expect(find.text('You are offline.'), findsOneWidget);
      expect(retried, isTrue);
    });

    testWidgets('se anuncia como región viva', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpInApp(
        tester,
        const QaBanner(kind: QaBannerKind.stale, message: 'Out of date.'),
      );

      final node = tester.getSemantics(find.bySemanticsLabel('Out of date.'));

      expect(node.flagsCollection.isLiveRegion, isTrue);
      handle.dispose();
    });
  });

  group('estados vacío y de error', () {
    testWidgets('vacío invita a actuar', (tester) async {
      var acted = false;
      await pumpInApp(
        tester,
        QaEmptyState(
          icon: Icons.inbox_outlined,
          title: 'Nothing yet',
          message: 'Pick a time slot.',
          actionLabel: 'Subscribe',
          onAction: () => acted = true,
        ),
      );

      await tester.tap(find.text('Subscribe'));

      expect(find.text('Nothing yet'), findsOneWidget);
      expect(acted, isTrue);
    });

    testWidgets('error dice la causa y ofrece reintentar', (tester) async {
      var retried = false;
      await pumpInApp(
        tester,
        QaErrorState(
          title: 'Could not load',
          message: 'No connection.',
          retryLabel: 'Retry',
          onRetry: () => retried = true,
        ),
      );

      await tester.tap(find.text('Retry'));

      expect(find.text('No connection.'), findsOneWidget);
      expect(retried, isTrue);
    });
  });

  group('QaKpi', () {
    testWidgets('éxito muestra cifra y texto secundario', (tester) async {
      await pumpInApp(
        tester,
        const QaKpi(label: 'Free spaces', value: '34', caption: 'of 120'),
      );

      expect(find.text('34'), findsOneWidget);
      expect(find.text('of 120'), findsOneWidget);
    });

    testWidgets('cargando, vacío y error tienen su propio contenido', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        const Column(
          children: [
            QaKpi.loading(label: 'A', semanticLabel: 'Loading'),
            QaKpi.empty(label: 'B', emptyText: 'No data yet'),
            QaKpi.error(label: 'C', errorText: 'Could not load'),
          ],
        ),
      );

      expect(find.byType(QaSkeleton), findsWidgets);
      expect(find.textContaining('No data yet'), findsOneWidget);
      expect(find.text('Could not load'), findsOneWidget);
    });

    testWidgets('desactualizado agrega la etiqueta de antigüedad', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        const QaKpi(
          label: 'Free spaces',
          value: '34',
          staleLabel: 'No new data since 8:42',
        ),
      );

      expect(find.byType(QaFreshnessLabel), findsOneWidget);
    });

    testWidgets('semántica junta etiqueta, cifra y texto', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpInApp(
        tester,
        const QaKpi(label: 'Free spaces', value: '34', caption: 'of 120'),
      );

      expect(
        find.bySemanticsLabel('Free spaces, 34, of 120'),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('QaArrivalPlate', () {
    testWidgets('muestra la categoría traducida, no el código', (tester) async {
      await pumpInApp(
        tester,
        const QaArrivalPlate(
          headline: 'You arrive in 18 min',
          categoryLabel: 'High',
          tone: QaTone.free,
          detail: '82% chance of finding a space',
          footnote: 'Medium confidence · 8:41',
        ),
      );

      expect(find.text('High'), findsOneWidget);
      expect(find.text('HIGH'), findsNothing);
      expect(find.text('You arrive in 18 min'), findsOneWidget);
    });

    testWidgets('semántica lee toda la placa como un solo nodo', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpInApp(
        tester,
        const QaArrivalPlate(
          headline: 'You arrive in 18 min',
          categoryLabel: 'High',
          tone: QaTone.free,
          detail: '82% chance',
          note: 'Estimate based on limited data',
          footnote: '8:41',
          isPartial: true,
        ),
      );

      expect(
        find.bySemanticsLabel(
          'You arrive in 18 min. High. 82% chance. '
          'Estimate based on limited data. 8:41',
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('cargando muestra skeleton y su etiqueta', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpInApp(
        tester,
        const QaArrivalPlate.loading(semanticLabel: 'Loading'),
      );

      expect(find.byType(QaSkeleton), findsWidgets);
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
      handle.dispose();
    });
  });

  group('QaHorizonBars', () {
    const bars = [
      QaHorizonBarData(
        label: '15 min',
        semanticLabel: 'In 15 minutes: 42% occupied',
        valueLabel: '42%',
        fraction: 0.42,
        tone: QaTone.free,
      ),
      QaHorizonBarData(
        label: '30 min',
        semanticLabel: 'In 30 minutes: no forecast',
        status: QaHorizonBarStatus.missing,
      ),
      QaHorizonBarData(
        label: '45 min',
        semanticLabel: 'In 45 minutes: forecast expired',
        status: QaHorizonBarStatus.expired,
      ),
    ];

    testWidgets('muestra rótulos, cifras y la saturación prevista', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        const QaHorizonBars(bars: bars, saturationLabel: 'Fills up at 9:20'),
      );

      expect(find.text('15 min'), findsOneWidget);
      expect(find.text('42%'), findsOneWidget);
      expect(find.text('Fills up at 9:20'), findsOneWidget);
    });

    testWidgets('cada barra tiene su descripción, incluidas las faltantes '
        'y vencidas', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpInApp(tester, const QaHorizonBars(bars: bars));

      expect(
        find.bySemanticsLabel('In 15 minutes: 42% occupied'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('In 30 minutes: no forecast'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('In 45 minutes: forecast expired'),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('QaBanner error', () {
    testWidgets('con requestFocus recibe el foco al aparecer y al cambiar', (
      tester,
    ) async {
      final message = ValueNotifier('First error');
      addTearDown(message.dispose);
      await pumpInApp(
        tester,
        ValueListenableBuilder<String>(
          valueListenable: message,
          builder: (context, text, _) => QaBanner(
            kind: QaBannerKind.error,
            message: text,
            requestFocus: true,
          ),
        ),
      );
      await tester.pump();

      expect(FocusManager.instance.primaryFocus?.debugLabel, 'QaBanner');
      expect(find.text('First error'), findsOneWidget);

      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();
      expect(FocusManager.instance.primaryFocus?.debugLabel, isNot('QaBanner'));

      message.value = 'Second error';
      await tester.pump();
      await tester.pump();

      expect(FocusManager.instance.primaryFocus?.debugLabel, 'QaBanner');
      expect(find.text('Second error'), findsOneWidget);
    });

    testWidgets('sin requestFocus no roba el foco', (tester) async {
      await pumpInApp(
        tester,
        const QaBanner(kind: QaBannerKind.error, message: 'Quiet error'),
      );
      await tester.pump();

      expect(FocusManager.instance.primaryFocus?.debugLabel, isNot('QaBanner'));
    });
  });
}

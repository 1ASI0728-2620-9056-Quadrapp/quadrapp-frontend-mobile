// Componentes nuevos del rediseño: lo que tienen de lógica (movimiento que
// ocurre una vez, estado real de la conexión, ventanas) y las guías de
// accesibilidad. Lo puramente visual se revisa en las capturas.
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/design_system/painters/qa_illustrations.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/pump_screen.dart';

Future<void> _expectAccessible(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
}

void main() {
  group('qaRingArcs', () {
    test('reparte el anillo en proporción a las cuentas, en orden', () {
      final arcs = qaRingArcs(free: 45, occupied: 72, unknown: 3);

      expect(arcs.map((a) => a.segment), [
        QaRingSegment.free,
        QaRingSegment.occupied,
        QaRingSegment.unknown,
      ]);
      expect(arcs[0].sweep / arcs[1].sweep, closeTo(45 / 72, 1e-9));
      expect(arcs[1].sweep / arcs[2].sweep, closeTo(72 / 3, 1e-9));
    });

    test('los tramos no se solapan y caben en una vuelta', () {
      final arcs = qaRingArcs(free: 5, occupied: 5, unknown: 5);

      for (var i = 1; i < arcs.length; i++) {
        expect(
          arcs[i].start,
          greaterThan(arcs[i - 1].start + arcs[i - 1].sweep),
        );
      }
      expect(arcs.last.start + arcs.last.sweep, lessThanOrEqualTo(1));
    });

    test('un solo tramo ocupa la vuelta entera, sin hueco', () {
      final arcs = qaRingArcs(free: 0, occupied: 78, unknown: 0);

      expect(arcs, hasLength(1));
      expect(arcs.single.start, 0);
      expect(arcs.single.sweep, 1);
    });

    test('sin espacios no hay tramos', () {
      expect(qaRingArcs(free: 0, occupied: 0, unknown: 0), isEmpty);
    });
  });

  group('QaCountUp', () {
    testWidgets('sin animaciones muestra el valor al instante', (tester) async {
      await pumpInApp(tester, const QaCountUp(value: 45));

      expect(find.text('45'), findsOneWidget);
    });

    testWidgets('cuenta desde 0 hasta su valor, una sola vez', (tester) async {
      await pumpInApp(
        tester,
        const QaCountUp(value: 45),
        disableAnimations: false,
      );
      expect(find.text('0'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 300));
      final middle = int.parse(
        tester.widget<Text>(find.byType(Text)).data!,
      );
      expect(middle, inInclusiveRange(1, 44));

      await tester.pumpAndSettle();
      expect(find.text('45'), findsOneWidget);

      // Un cambio posterior (tiempo real) se muestra de inmediato.
      await pumpInApp(
        tester,
        const QaCountUp(value: 46),
        disableAnimations: false,
      );
      expect(find.text('46'), findsOneWidget);
      // El tema de la app se reasigna al volver a montar: se deja asentar.
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('se anuncia con su valor final, no con los intermedios', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpInApp(
        tester,
        const QaCountUp(value: 45),
        disableAnimations: false,
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.bySemanticsLabel('45'), findsOneWidget);
      handle.dispose();
    });
  });

  group('QaLiveBadge: refleja el estado real de la conexión', () {
    testWidgets('cada estado se distingue por su ícono y no anima', (
      tester,
    ) async {
      const icons = {
        QaLiveStatus.live: Icons.wifi_rounded,
        QaLiveStatus.reconnecting: Icons.wifi_find_rounded,
        QaLiveStatus.offline: Icons.wifi_off_rounded,
      };
      for (final status in QaLiveStatus.values) {
        await pumpInApp(
          tester,
          QaLiveBadge(status: status, label: status.name),
          disableAnimations: false,
        );
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.byIcon(icons[status]!), findsOneWidget);
        // El estado cambia, no parpadea: nada queda animándose.
        expect(tester.hasRunningAnimations, isFalse);
      }
    });

    testWidgets('cada estado dice su texto y se anuncia como región viva', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      for (final status in QaLiveStatus.values) {
        await pumpInApp(
          tester,
          QaLiveBadge(status: status, label: status.name),
        );
        expect(find.text(status.name), findsOneWidget);
        expect(find.bySemanticsLabel(status.name), findsOneWidget);
      }
      handle.dispose();
    });
  });

  group('QaStagger', () {
    testWidgets('aparece una sola vez y no se repite al reconstruir', (
      tester,
    ) async {
      Widget host(String text) => QaStagger(index: 2, child: Text(text));
      await pumpInApp(tester, host('a'), disableAnimations: false);
      expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0);

      await tester.pumpAndSettle();
      expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);

      await pumpInApp(tester, host('b'), disableAnimations: false);
      expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('un índice mayor aparece más tarde', (tester) async {
      await pumpInApp(
        tester,
        const Column(
          children: [
            QaStagger(index: 0, child: Text('first')),
            QaStagger(index: 5, child: Text('later')),
          ],
        ),
        disableAnimations: false,
      );
      await tester.pump(const Duration(milliseconds: 150));

      final opacities = tester
          .widgetList<Opacity>(find.byType(Opacity))
          .map((o) => o.opacity)
          .toList();
      expect(opacities[0], greaterThan(opacities[1]));
      await tester.pumpAndSettle();
    });

    testWidgets('sin animaciones aparece de inmediato', (tester) async {
      await pumpInApp(tester, const QaStagger(index: 5, child: Text('x')));

      expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
    });
  });

  group('QaLoadingRegion (brillo del skeleton)', () {
    Widget region() => const QaLoadingRegion(
      semanticLabel: 'Loading',
      child: QaSkeleton(width: 100),
    );

    testWidgets('con animaciones brilla unos segundos y luego se detiene', (
      tester,
    ) async {
      await pumpInApp(tester, region(), disableAnimations: false);
      await tester.pump(const Duration(seconds: 1));
      expect(tester.hasRunningAnimations, isTrue);

      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('sin animaciones es estático', (tester) async {
      await pumpInApp(tester, region());
      await tester.pump(const Duration(seconds: 1));

      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('QaCard', () {
    testWidgets('con onTap es un solo objetivo táctil con su resumen', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var taps = 0;
      await pumpInApp(
        tester,
        QaCard(
          onTap: () => taps++,
          semanticLabel: 'Pabellón A, 45 free',
          semanticHint: 'Opens the lot',
          child: const Text('Pabellón A'),
        ),
      );

      expect(find.bySemanticsLabel('Pabellón A, 45 free'), findsOneWidget);
      await tester.tap(find.text('Pabellón A'));
      expect(taps, 1);
      await _expectAccessible(tester);
      handle.dispose();
    });

    testWidgets('se encoge a 0,98 mientras se toca, salvo sin animaciones', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        QaCard(onTap: () {}, child: const Text('x')),
        disableAnimations: false,
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('x')),
      );
      await tester.pump();
      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        QaPressScale.pressedScale,
      );

      await gesture.up();
      await tester.pumpAndSettle();
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);

      await pumpInApp(tester, QaCard(onTap: () {}, child: const Text('x')));
      final still = await tester.startGesture(tester.getCenter(find.text('x')));
      await tester.pump();
      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
      await still.up();
    });

    testWidgets('el héroe lleva degradado y sin borde', (tester) async {
      await pumpInApp(
        tester,
        const QaCard(hero: true, child: Text('x')),
      );

      final decoration = tester
          .widgetList<DecoratedBox>(find.byType(DecoratedBox))
          .map((box) => box.decoration)
          .whereType<BoxDecoration>()
          .firstWhere((d) => d.gradient != null);
      expect(decoration.border, isNull);
      expect(decoration.boxShadow, isNotEmpty);
    });
  });

  group('QaBottomSheet', () {
    final openerFocus = FocusNode();

    tearDownAll(openerFocus.dispose);

    Widget host({Widget? footer, double bodyHeight = 40}) => Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: ElevatedButton(
            focusNode: openerFocus,
            onPressed: () => showQaBottomSheet<String>(
              context,
              builder: (context) => QaBottomSheet(
                title: 'New alert',
                closeLabel: 'Close',
                footer:
                    footer ??
                    QaButton(
                      label: 'Save alert',
                      size: QaButtonSize.large,
                      expand: true,
                      onPressed: () => Navigator.of(context).pop('saved'),
                    ),
                child: SizedBox(
                  height: bodyHeight,
                  child: const TextField(),
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

    Future<void> open(WidgetTester tester) async {
      openerFocus.requestFocus();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('abre con título de encabezado, cuerpo y acción fija', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpScreen(tester, host());
      await open(tester);

      expect(find.text('New alert'), findsOneWidget);
      expect(find.text('Save alert'), findsOneWidget);
      expect(find.byTooltip('Close'), findsOneWidget);
      expect(
        tester.getSemantics(find.text('New alert')).flagsCollection.isHeader,
        isTrue,
      );
      handle.dispose();
    });

    for (final (name, scale, dark) in [
      ('claro', 1.0, false),
      ('texto al 200 %', 2.0, false),
      ('oscuro', 1.0, true),
    ]) {
      testWidgets('$name: accesible, sin desbordes', (tester) async {
        final handle = tester.ensureSemantics();
        await pumpScreen(
          tester,
          host(),
          textScale: scale,
          brightness: dark ? Brightness.dark : Brightness.light,
          size: const Size(360, 640),
        );
        await open(tester);

        expect(tester.takeException(), isNull);
        await _expectAccessible(tester);
        handle.dispose();
      });
    }

    testWidgets('el botón de cerrar mide 48 dp y cierra', (tester) async {
      await pumpScreen(tester, host());
      await open(tester);

      final size = tester.getSize(find.byTooltip('Close'));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      expect(find.text('New alert'), findsNothing);
    });

    testWidgets('se cierra con un gesto hacia abajo', (tester) async {
      await pumpScreen(tester, host());
      await open(tester);

      await tester.drag(find.text('New alert'), const Offset(0, 600));
      await tester.pumpAndSettle();

      expect(find.text('New alert'), findsNothing);
    });

    testWidgets('la acción primaria devuelve el resultado', (tester) async {
      String? result;
      await pumpScreen(
        tester,
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await showQaBottomSheet<String>(
                context,
                builder: (context) => QaBottomSheet(
                  title: 'T',
                  closeLabel: 'Close',
                  footer: QaButton(
                    label: 'Save',
                    onPressed: () => Navigator.of(context).pop('saved'),
                  ),
                  child: const SizedBox.shrink(),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result, 'saved');
    });

    testWidgets('sube con el teclado y la acción primaria sigue a la vista', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        host(bodyHeight: 600),
      );
      await open(tester);

      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();

      expect(
        tester.getRect(find.text('Save alert')).bottom,
        lessThanOrEqualTo(800 - 300),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('en pantallas grandes mide como mucho 480 dp', (tester) async {
      await pumpScreen(tester, host(), size: const Size(900, 800));
      await open(tester);

      expect(
        tester.getSize(find.byType(QaBottomSheet)).width,
        lessThanOrEqualTo(qaBottomSheetMaxWidth),
      );
    });

    testWidgets('el foco pasa al título al abrir y vuelve al cerrar', (
      tester,
    ) async {
      await pumpScreen(tester, host());
      await open(tester);

      final focused = FocusManager.instance.primaryFocus!.context!;
      expect(
        find.descendant(
          of: find.byElementPredicate((e) => e == focused),
          matching: find.text('New alert'),
        ),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(FocusManager.instance.primaryFocus, openerFocus);
    });
  });

  group('QaConfirmDialog', () {
    Widget host({
      bool destructive = true,
      void Function({required bool confirmed})? onResult,
    }) => Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            final confirmed = await showQaConfirmDialog(
              context,
              title: 'Delete alert?',
              subject: 'Pabellón A · Mon–Fri 7:30–9:00',
              message: 'You will stop receiving alerts for it.',
              confirmLabel: 'Delete',
              cancelLabel: 'Cancel',
              icon: Icons.notifications_outlined,
              destructive: destructive,
            );
            onResult?.call(confirmed: confirmed);
          },
          child: const Text('open'),
        ),
      ),
    );

    testWidgets('nombra el objeto afectado y el mensaje', (tester) async {
      await pumpScreen(tester, host());
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Pabellón A · Mon–Fri 7:30–9:00'), findsOneWidget);
      expect(
        find.text('You will stop receiving alerts for it.'),
        findsOneWidget,
      );
    });

    testWidgets('confirmar devuelve true y cancelar, false', (tester) async {
      final results = <bool>[];
      await pumpScreen(
        tester,
        host(onResult: ({required confirmed}) => results.add(confirmed)),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(results, [true, false]);
    });

    testWidgets('destructivo: el botón va en Alert y el foco empieza en '
        'cancelar', (tester) async {
      await pumpScreen(tester, host());
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final confirm = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Delete'),
      );
      final colors = Theme.of(
        tester.element(find.byType(AlertDialog)),
      ).extension<QaColors>()!;
      expect(
        confirm.style!.backgroundColor!.resolve({}),
        colors.full,
      );
      final focused = FocusManager.instance.primaryFocus!.context!;
      expect(
        find.descendant(
          of: find.byElementPredicate((e) => e == focused),
          matching: find.text('Cancel'),
        ),
        findsWidgets,
      );
    });

    for (final (name, scale, dark) in [
      ('claro', 1.0, false),
      ('texto al 200 %', 2.0, false),
      ('oscuro', 1.0, true),
    ]) {
      testWidgets('$name: accesible, sin desbordes', (tester) async {
        final handle = tester.ensureSemantics();
        await pumpScreen(
          tester,
          host(),
          textScale: scale,
          brightness: dark ? Brightness.dark : Brightness.light,
          size: const Size(360, 640),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        await _expectAccessible(tester);
        handle.dispose();
      });
    }
  });

  group('QaSnackbar', () {
    Widget host({VoidCallback? onUndo}) => Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => showQaSnackbar(
            context,
            message: 'Alert saved',
            undoLabel: 'Undo',
            onUndo: onUndo,
          ),
          child: const Text('open'),
        ),
      ),
      bottomNavigationBar: const SizedBox(height: 72),
    );

    testWidgets('muestra el aviso con Undo y deshace', (tester) async {
      var undone = 0;
      await pumpScreen(tester, host(onUndo: () => undone++));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Alert saved'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(undone, 1);
    });

    testWidgets('sale sobre la barra inferior', (tester) async {
      await pumpScreen(tester, host(onUndo: () {}));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(
        tester.getRect(find.byType(SnackBar)).bottom,
        lessThanOrEqualTo(800 - 72),
      );
    });

    testWidgets('dura lo bastante para tocar Undo y luego desaparece', (
      tester,
    ) async {
      await pumpScreen(tester, host(onUndo: () {}));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.pump(const Duration(seconds: 4));
      expect(find.text('Alert saved'), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('Alert saved'), findsNothing);
    });

    for (final (name, scale, dark) in [
      ('claro', 1.0, false),
      ('texto al 200 %', 2.0, false),
      ('oscuro', 1.0, true),
    ]) {
      testWidgets('$name: accesible, sin desbordes', (tester) async {
        final handle = tester.ensureSemantics();
        await pumpScreen(
          tester,
          host(onUndo: () {}),
          textScale: scale,
          brightness: dark ? Brightness.dark : Brightness.light,
          size: const Size(360, 640),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        await _expectAccessible(tester);
        handle.dispose();
      });
    }
  });

  group('QaIllustration', () {
    for (final kind in QaIllustrationKind.values) {
      for (final colors in [QaColors.light, QaColors.dark]) {
        test('${kind.name} se dibuja sin errores', () {
          final recorder = ui.PictureRecorder();

          QaIllustrationPainter(kind: kind, colors: colors).paint(
            Canvas(recorder),
            const Size(240, 150),
          );

          expect(recorder.endRecording, returnsNormally);
        });
      }
    }

    testWidgets('es decorativa: no expone semántica', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpInApp(
        tester,
        const QaIllustration(kind: QaIllustrationKind.parking),
      );

      expect(
        find.descendant(
          of: find.byType(QaIllustration),
          matching: find.byType(ExcludeSemantics),
        ),
        findsWidgets,
      );
      handle.dispose();
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/app/gallery/gallery_data.dart';
import 'package:quadrapp_mobile/app/gallery/gallery_depth.dart';
import 'package:quadrapp_mobile/app/gallery/gallery_inputs.dart';
import 'package:quadrapp_mobile/app/gallery/gallery_page.dart';
import 'package:quadrapp_mobile/app/gallery/gallery_palette.dart';
import 'package:quadrapp_mobile/app/gallery/gallery_status.dart';
import 'package:quadrapp_mobile/contexts/iam/presentation/pages/login_page.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/pump_app.dart';

typedef _Section = ({String name, Widget widget});

const List<_Section> _sections = [
  (name: 'paleta', widget: GalleryPalette()),
  (name: 'profundidad', widget: GalleryDepth()),
  (name: 'datos', widget: GalleryData()),
  (name: 'estado', widget: GalleryStatus()),
  (name: 'entradas', widget: GalleryInputs()),
];

void main() {
  group('accesibilidad de la galería', () {
    for (final brightness in Brightness.values) {
      for (final locale in const [Locale('en'), Locale('es')]) {
        for (final section in _sections) {
          final id = '${section.name} · ${brightness.name} · $locale';

          testWidgets('$id: objetivos táctiles y etiquetas', (tester) async {
            final handle = tester.ensureSemantics();
            await pumpInApp(
              tester,
              section.widget,
              brightness: brightness,
              locale: locale,
              size: const Size(400, 9000),
            );

            await expectLater(
              tester,
              meetsGuideline(androidTapTargetGuideline),
            );
            await expectLater(
              tester,
              meetsGuideline(labeledTapTargetGuideline),
            );
            handle.dispose();
          });

          testWidgets('$id: contraste de texto', (tester) async {
            final handle = tester.ensureSemantics();
            await pumpInApp(
              tester,
              section.widget,
              brightness: brightness,
              locale: locale,
              size: const Size(400, 9000),
            );

            await expectLater(tester, meetsGuideline(textContrastGuideline));
            handle.dispose();
          });
        }
      }
    }
  });

  group('texto escalado al 200 %', () {
    for (final section in _sections) {
      testWidgets('${section.name}: sin desbordes ni texto cortado', (
        tester,
      ) async {
        await pumpInApp(
          tester,
          section.widget,
          textScale: 2,
          size: const Size(360, 800),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
      });
    }
  });

  group('cada componente en sus estados', () {
    testWidgets('la galería muestra los cinco estados en el idioma activo', (
      tester,
    ) async {
      await pumpInApp(
        tester,
        const GalleryData(),
        size: const Size(400, 6000),
      );

      for (final state in const [
        'Loading',
        'Empty',
        'Error',
        'Partial or out of date',
        'Success',
      ]) {
        expect(find.text(state), findsWidgets, reason: state);
      }
      for (final component in const [
        'QaArrivalPlate',
        'QaHorizonBars',
        'QaSpaceMap',
        'QaKpi',
      ]) {
        expect(find.text(component), findsOneWidget, reason: component);
      }
    });

    testWidgets('los textos salen del idioma activo (español)', (tester) async {
      await pumpInApp(
        tester,
        const GalleryStatus(),
        locale: const Locale('es'),
        size: const Size(400, 9000),
      );

      expect(find.text('Cargando'), findsWidgets);
      expect(find.text('Parcial o desactualizado'), findsWidgets);
      expect(find.text('Loading'), findsNothing);
    });
  });

  group('ruta /gallery', () {
    testWidgets('en debug, la ruta abre la galería (sin sesión)', (
      tester,
    ) async {
      tester.view
        ..physicalSize = const Size(400, 900)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final harness = await AppHarness.create(enableGallery: true);
      addTearDown(harness.dispose);
      await tester.pumpWidget(harness.app());
      await tester.pumpAndSettle();

      harness.router.go(galleryPath);
      await tester.pumpAndSettle();

      expect(find.byType(GalleryPage), findsOneWidget);
    });

    testWidgets('fuera de debug no existe la ruta', (tester) async {
      final harness = await AppHarness.create();
      addTearDown(harness.dispose);
      await tester.pumpWidget(harness.app());
      await tester.pumpAndSettle();

      harness.router.go(galleryPath);
      await tester.pumpAndSettle();

      expect(find.byType(GalleryPage), findsNothing);
      expect(find.byType(LoginPage), findsOneWidget);
    });
  });
}

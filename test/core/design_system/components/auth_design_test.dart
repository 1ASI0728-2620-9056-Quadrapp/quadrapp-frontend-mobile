// US01: el andamio de las pantallas de acceso y los controles rediseñados.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';

import '../../../helpers/pump_app.dart';
import '../../../helpers/pump_screen.dart';

Widget _form({VoidCallback? onBack, QaBanner? banner, bool loading = false}) =>
    QaAuthScaffold(
      heading: 'Plan your arrival at campus',
      topBarTitle: onBack == null ? null : 'Verify your email',
      icon: onBack == null ? null : Icons.mark_email_read_outlined,
      onBack: onBack,
      backLabel: 'Back',
      footer: const Text('Legal line'),
      children: [
        const Text('Check the estimated availability before you leave.'),
        const SizedBox(height: QaSpacing.xl),
        const QaTextField(
          label: 'Institutional email',
          hint: 'name@university.edu',
          helperText: 'We use your domain.',
        ),
        QaBannerSlot(banner: banner),
        const SizedBox(height: QaSpacing.xl),
        QaButton(
          label: 'Continue',
          loadingLabel: 'Sending code…',
          isLoading: loading,
          trailingIcon: Icons.arrow_forward_rounded,
          size: QaButtonSize.large,
          expand: true,
          onPressed: () {},
        ),
      ],
    );

void main() {
  group('QaAuthScaffold', () {
    for (final (name, size, scale) in [
      ('360×800', const Size(360, 800), 1.0),
      ('360×640', const Size(360, 640), 1.0),
      ('360×640 con texto al 200 %', const Size(360, 640), 2.0),
      ('411×891', const Size(411, 891), 1.0),
    ]) {
      for (final withBack in [false, true]) {
        testWidgets(
          '$name${withBack ? ' con volver' : ''}: sin desbordes y con las '
          'guías de accesibilidad',
          (tester) async {
            final handle = tester.ensureSemantics();
            await pumpScreen(
              tester,
              _form(onBack: withBack ? () {} : null),
              size: size,
              textScale: scale,
            );

            expect(tester.takeException(), isNull);
            expect(find.text('Plan your arrival at campus'), findsOneWidget);
            await expectLater(
              tester,
              meetsGuideline(androidTapTargetGuideline),
            );
            await expectLater(
              tester,
              meetsGuideline(labeledTapTargetGuideline),
            );
            await expectLater(tester, meetsGuideline(textContrastGuideline));
            handle.dispose();
          },
        );
      }
    }

    testWidgets('modo oscuro: sin desbordes y con contraste', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpScreen(tester, _form(), brightness: Brightness.dark);

      expect(tester.takeException(), isNull);
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('sin volver lleva el logo y Quadrapp arriba, y el titular '
        'como encabezado', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpScreen(tester, _form());

      expect(find.byType(QaBrandMark), findsOneWidget);
      expect(find.text('Quadrapp'), findsOneWidget);
      expect(find.byType(QaTopBar), findsNothing);
      expect(
        tester.getSemantics(find.text('Plan your arrival at campus')),
        matchesSemantics(label: 'Plan your arrival at campus', isHeader: true),
      );
      handle.dispose();
    });

    testWidgets('con volver lleva la barra con la flecha, el recuadro menta y '
        'el titular', (tester) async {
      await pumpScreen(tester, _form(onBack: () {}));

      expect(find.byType(QaTopBar), findsOneWidget);
      expect(find.text('Verify your email'), findsOneWidget);
      expect(find.byIcon(Icons.mark_email_read_outlined), findsOneWidget);
      expect(find.text('Quadrapp'), findsNothing);
    });

    testWidgets('el pie queda anclado abajo cuando el contenido es corto', (
      tester,
    ) async {
      await pumpScreen(tester, _form());

      expect(
        tester.getRect(find.text('Legal line')).bottom,
        greaterThan(700),
      );
    });

    testWidgets('el botón atrás mide 48 dp y llama a onBack', (tester) async {
      var taps = 0;
      await pumpScreen(tester, _form(onBack: () => taps++));

      final size = tester.getSize(find.byType(IconButton));
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));
      await tester.tap(find.byTooltip('Back'));
      expect(taps, 1);
    });

    testWidgets('con el teclado abierto el contenido se desplaza hasta el '
        'botón, que queda sobre el teclado', (tester) async {
      await pumpScreen(
        tester,
        _form(),
        size: const Size(360, 640),
        keyboardHeight: 280,
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Continue'));
      await tester.pumpAndSettle();

      expect(
        tester.getRect(find.text('Continue')).bottom,
        lessThanOrEqualTo(640 - 280),
      );
    });
  });

  group('QaButton rediseñado', () {
    testWidgets('cargando conserva el texto y el ancho', (tester) async {
      await pumpInApp(
        tester,
        QaButton(
          label: 'Send code',
          loadingLabel: 'Sending code…',
          size: QaButtonSize.large,
          expand: true,
          onPressed: () {},
        ),
      );
      final normal = tester.getSize(find.byType(FilledButton));
      expect(normal.height, 56);

      await pumpInApp(
        tester,
        QaButton(
          label: 'Send code',
          loadingLabel: 'Sending code…',
          isLoading: true,
          size: QaButtonSize.large,
          expand: true,
          onPressed: () {},
        ),
      );

      expect(find.text('Sending code…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.getSize(find.byType(FilledButton)), normal);
      // El indicador va a la izquierda del texto.
      expect(
        tester.getCenter(find.byType(CircularProgressIndicator)).dx,
        lessThan(tester.getCenter(find.text('Sending code…')).dx),
      );
    });

    testWidgets('deshabilitado se ve distinto: relleno, borde y texto, no '
        'solo opacidad', (tester) async {
      await pumpInApp(
        tester,
        const QaButton(label: 'Send code', onPressed: null),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      final states = <WidgetState>{WidgetState.disabled};
      final colors = Theme.of(
        tester.element(find.byType(FilledButton)),
      ).extension<QaColors>()!;
      expect(
        button.style!.backgroundColor!.resolve(states),
        colors.surfaceMuted,
      );
      final shape =
          button.style!.shape!.resolve(states)! as RoundedRectangleBorder;
      expect(shape.side.width, 1.5);
      expect(
        button.style!.foregroundColor!.resolve(states),
        colors.onSurfaceMuted,
      );
    });

    testWidgets('presionado oscurece el relleno', (tester) async {
      await pumpInApp(tester, QaButton(label: 'OK', onPressed: () {}));

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      final normal = button.style!.backgroundColor!.resolve({});
      final pressed = button.style!.backgroundColor!.resolve({
        WidgetState.pressed,
      });
      expect(pressed, isNot(normal));
      expect(pressed!.computeLuminance(), lessThan(normal!.computeLuminance()));
    });
  });

  group('QaTextField del diseño', () {
    testWidgets('la etiqueta va encima, la ayuda debajo y el error lleva '
        'ícono y texto', (tester) async {
      await pumpInApp(
        tester,
        const QaTextField(
          label: 'Institutional email',
          hint: 'name@university.edu',
          helperText: 'We use your domain.',
          errorText: 'Enter a valid email.',
        ),
      );

      expect(find.text('Institutional email'), findsOneWidget);
      expect(find.text('name@university.edu'), findsOneWidget);
      expect(find.text('Enter a valid email.'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Institutional email')).dy,
        lessThan(tester.getTopLeft(find.byType(TextFormField)).dy),
      );
    });

    testWidgets('el campo mide al menos 48 dp y se anuncia con su etiqueta', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpInApp(
        tester,
        const QaTextField(label: 'Institutional email'),
      );

      expect(
        tester.getSize(find.byType(TextFormField)).height,
        greaterThanOrEqualTo(48),
      );
      expect(
        find.bySemanticsLabel(RegExp('Institutional email')),
        findsWidgets,
      );
      handle.dispose();
    });
  });

  group('QaOtpField rediseñado', () {
    Future<List<Size>> cellSizes(WidgetTester tester, double width) async {
      await pumpInApp(
        tester,
        SizedBox(
          width: width,
          child: const QaOtpField(semanticLabel: 'Code'),
        ),
        size: const Size(500, 900),
      );
      return [
        for (final cell
            in find
                .descendant(
                  of: find.byType(QaOtpField),
                  matching: find.byType(DecoratedBox),
                )
                .evaluate())
          tester.getSize(find.byElementPredicate((e) => e == cell)),
      ];
    }

    testWidgets('con espacio las casillas son de 48×56 con 8 dp entre ellas', (
      tester,
    ) async {
      final sizes = await cellSizes(tester, 360);

      expect(sizes, hasLength(6));
      for (final size in sizes) {
        expect(size, const Size(48, 56));
      }
    });

    testWidgets('a 360 dp (312 de formulario) se achican por igual', (
      tester,
    ) async {
      final sizes = await cellSizes(tester, 312);

      for (final size in sizes) {
        expect(size.width, closeTo((312 - 40) / 6, 0.01));
        expect(size.height, 56);
      }
    });
  });

  group('QaBannerSlot', () {
    testWidgets('el aviso aparece animando la altura, sin saltos', (
      tester,
    ) async {
      Widget host(QaBanner? banner) => Column(
        children: [
          QaBannerSlot(banner: banner),
          const SizedBox(key: Key('below'), height: 10),
        ],
      );
      await pumpInApp(tester, host(null), disableAnimations: false);
      final before = tester.getTopLeft(find.byKey(const Key('below'))).dy;

      await pumpInApp(
        tester,
        host(const QaBanner(kind: QaBannerKind.error, message: 'Oops')),
        disableAnimations: false,
      );
      await tester.pump(const Duration(milliseconds: 100));
      final middle = tester.getTopLeft(find.byKey(const Key('below'))).dy;
      await tester.pumpAndSettle();
      final after = tester.getTopLeft(find.byKey(const Key('below'))).dy;

      expect(middle, greaterThan(before));
      expect(middle, lessThan(after));
      expect(find.text('Oops'), findsOneWidget);
    });
  });
}

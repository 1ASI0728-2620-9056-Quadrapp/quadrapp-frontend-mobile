// US04: el chip de sede, la ventana para elegir y el aviso de elegir sede, con
// las guías de accesibilidad.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quadrapp_mobile/composition/sede/sede_chip.dart';
import 'package:quadrapp_mobile/composition/sede/sede_cubit.dart';
import 'package:quadrapp_mobile/composition/sede/sede_prompt.dart';
import 'package:quadrapp_mobile/composition/sede/sede_state.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

import '../../helpers/pump_screen.dart';

class _MockSedeCubit extends MockCubit<ViewState<SedeSelection>>
    implements SedeCubit {}

ParkingLot _lot(int id, String name, {int layoutVersion = 3}) => ParkingLot(
  id: LotId(id),
  name: name,
  address: 'Av. Prueba $id',
  layoutVersion: layoutVersion,
  staleAfter: const Duration(seconds: 180),
);

void main() {
  late _MockSedeCubit cubit;
  final lots = [
    _lot(1, 'Monterrico'),
    _lot(2, 'San Isidro'),
    _lot(3, 'San Miguel', layoutVersion: 0),
  ];

  setUpAll(() => registerFallbackValue(const LotId(1)));

  setUp(() {
    cubit = _MockSedeCubit();
    when(() => cubit.select(any())).thenAnswer((_) async {});
  });

  Future<void> pump(
    WidgetTester tester,
    ViewState<SedeSelection> state, {
    Widget? child,
    double textScale = 1,
    Brightness brightness = Brightness.light,
    Locale locale = const Locale('en'),
  }) async {
    whenListen(
      cubit,
      const Stream<ViewState<SedeSelection>>.empty(),
      initialState: state,
    );
    await pumpScreen(
      tester,
      BlocProvider<SedeCubit>.value(
        value: cubit,
        child: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: child ?? const Align(child: SedeChip()),
          ),
        ),
      ),
      textScale: textScale,
      brightness: brightness,
      locale: locale,
    );
  }

  ViewState<SedeSelection> chosen() =>
      ViewData(SedeSelection(lots: lots, selected: lots.first));

  Future<void> expectAccessible(WidgetTester tester) async {
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  }

  group('SedeChip', () {
    testWidgets('muestra la sede elegida y se anuncia como un botón', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester, chosen());

      expect(find.text('Monterrico'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Campus: Monterrico. Change campus'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('sin sede elegida dice «Choose campus»', (tester) async {
      await pump(tester, ViewData(SedeSelection(lots: lots)));

      expect(find.text('Choose campus'), findsOneWidget);
    });

    testWidgets('cargando es un bloque gris; con error o vacío, nada', (
      tester,
    ) async {
      await pump(tester, const ViewLoading<SedeSelection>());
      expect(find.byType(SedeChip), findsOneWidget);
      expect(find.text('Monterrico'), findsNothing);

      await pump(tester, const ViewEmpty<SedeSelection>());
      expect(find.byIcon(Icons.location_on_outlined), findsNothing);
    });

    for (final (scale, dark) in [(1.0, false), (2.0, false), (1.0, true)]) {
      testWidgets('accesible (${scale}x${dark ? ', oscuro' : ''})', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await pump(
          tester,
          chosen(),
          textScale: scale,
          brightness: dark ? Brightness.dark : Brightness.light,
        );

        expect(tester.takeException(), isNull);
        await expectAccessible(tester);
        handle.dispose();
      });
    }

    testWidgets('tocarlo abre la ventana con una opción por sede, la elegida '
        'marcada y la que no tiene disponibilidad avisada', (tester) async {
      await pump(tester, chosen());

      await tester.tap(find.text('Monterrico'));
      await tester.pumpAndSettle();

      expect(find.text('Choose your campus'), findsOneWidget);
      expect(find.text('San Isidro'), findsOneWidget);
      expect(find.text('San Miguel'), findsOneWidget);
      expect(find.text('No availability published yet'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('elegir otra sede la guarda y cierra la ventana', (
      tester,
    ) async {
      await pump(tester, chosen());
      await tester.tap(find.text('Monterrico'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('San Isidro'));
      await tester.pumpAndSettle();

      verify(() => cubit.select(const LotId(2))).called(1);
      expect(find.text('Choose your campus'), findsNothing);
    });

    testWidgets('la ventana es accesible y cada opción se lee entera', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester, chosen());
      await tester.tap(find.text('Monterrico'));
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel('Monterrico, Av. Prueba 1, Current campus'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('San Miguel, No availability published yet'),
        findsOneWidget,
      );
      await expectAccessible(tester);
      handle.dispose();
    });
  });

  group('SedePrompt', () {
    testWidgets('pide elegir y lista las sedes; tocar una la elige', (
      tester,
    ) async {
      final selection = SedeSelection(lots: lots);
      await pump(
        tester,
        ViewData(selection),
        child: SingleChildScrollView(child: SedePrompt(selection: selection)),
      );

      expect(find.text('Which campus are you heading to?'), findsOneWidget);
      expect(find.text('Monterrico'), findsOneWidget);
      await tester.tap(find.text('San Isidro'));

      verify(() => cubit.select(const LotId(2))).called(1);
    });

    testWidgets('en español, accesible y sin desbordes al 200 %', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final selection = SedeSelection(lots: lots);
      await pump(
        tester,
        ViewData(selection),
        child: SingleChildScrollView(child: SedePrompt(selection: selection)),
        textScale: 2,
        locale: const Locale('es'),
      );

      expect(find.text('¿A qué sede vas?'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await expectAccessible(tester);
      handle.dispose();
    });
  });
}

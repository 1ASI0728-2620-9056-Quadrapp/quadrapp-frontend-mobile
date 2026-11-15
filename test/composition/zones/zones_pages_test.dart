// US04, US06, US07, US08, TS13: Zonas, pabellón y nivel en cada estado, con las
// guías de accesibilidad.
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quadrapp_mobile/composition/sede/sede_cubit.dart';
import 'package:quadrapp_mobile/composition/sede/sede_state.dart';
import 'package:quadrapp_mobile/composition/zones/level_page.dart';
import 'package:quadrapp_mobile/composition/zones/zone_page.dart';
import 'package:quadrapp_mobile/composition/zones/zones_cubit.dart';
import 'package:quadrapp_mobile/composition/zones/zones_state.dart';
import 'package:quadrapp_mobile/composition/zones/zones_tab_page.dart';
import 'package:quadrapp_mobile/contexts/occupancy/occupancy.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/pump_screen.dart';
import 'support.dart';

class _MockZones extends MockCubit<ViewState<ZonesOverview>>
    implements ZonesCubit {}

class _MockSede extends MockCubit<ViewState<SedeSelection>>
    implements SedeCubit {}

void main() {
  late _MockZones zones;
  late _MockSede sede;
  late FakeClock clock;
  late StreamController<void> ticks;
  final opened = <String>[];
  var backs = 0;

  final lots = [lot(), lot(id: 2)];

  setUpAll(() => registerFallbackValue(lot()));

  setUp(() {
    zones = _MockZones();
    sede = _MockSede();
    clock = FakeClock();
    ticks = StreamController<void>.broadcast();
    opened.clear();
    backs = 0;
    when(() => zones.setLot(any())).thenAnswer((_) async {});
    when(() => zones.load()).thenAnswer((_) async {});
    when(() => zones.refresh()).thenAnswer((_) async {});
    when(() => sede.load()).thenAnswer((_) async {});
    when(() => sede.select(any())).thenAnswer((_) async {});
  });

  tearDown(() => ticks.close());

  ViewState<SedeSelection> chosen() =>
      ViewData(SedeSelection(lots: lots, selected: lots.first));

  Future<void> pumpPage(
    WidgetTester tester,
    Widget page,
    ViewState<ZonesOverview> state, {
    ViewState<SedeSelection>? sedeState,
    Brightness brightness = Brightness.light,
    Locale locale = const Locale('en'),
    double textScale = 1,
    Size size = const Size(360, 1800),
  }) async {
    whenListen(
      zones,
      const Stream<ViewState<ZonesOverview>>.empty(),
      initialState: state,
    );
    whenListen(
      sede,
      const Stream<ViewState<SedeSelection>>.empty(),
      initialState: sedeState ?? chosen(),
    );
    await pumpScreen(
      tester,
      MultiBlocProvider(
        providers: [
          BlocProvider<ZonesCubit>.value(value: zones),
          BlocProvider<SedeCubit>.value(value: sede),
        ],
        child: page,
      ),
      brightness: brightness,
      locale: locale,
      textScale: textScale,
      size: size,
    );
    await tester.pump();
  }

  Widget tab() => ZonesTabPage(
    clock: clock,
    tabIndex: 1,
    ticker: () => ticks.stream,
    onOpenZone: (id) => opened.add('zone ${id.value}'),
    onOpenLevel: (zone, level) =>
        opened.add('level ${zone.value}/${level.value}'),
  );

  Widget zonePage([int id = 11]) => ZonePage(
    zoneId: ZoneId(id),
    clock: clock,
    ticker: () => ticks.stream,
    onBack: () => backs++,
    onOpenLevel: (zone, level) =>
        opened.add('level ${zone.value}/${level.value}'),
  );

  Widget levelPage({int zone = 11, int level = 111}) => LevelPage(
    zoneId: ZoneId(zone),
    levelId: LevelId(level),
    clock: clock,
    ticker: () => ticks.stream,
    onBack: () => backs++,
  );

  Future<void> expectAccessible(WidgetTester tester) async {
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  }

  final states = <String, ViewState<ZonesOverview>>{
    'cargando (skeleton)': const ViewLoading(),
    'con datos': ViewData(overview()),
    'con la sede llena': ViewData(
      overview(
        lotOccupancy: occupancy(
          spaces: [
            for (var id = 1; id <= 8; id++)
              state(id, id == 3 ? SpaceStatus.unknown : SpaceStatus.occupied),
          ],
        ),
      ),
    ),
    'dato vencido': ViewData(
      overview(lotOccupancy: occupancy(age: const Duration(minutes: 25))),
    ),
    'sin conexión (caché)': ViewData(
      overview(
        lotOccupancy: occupancy(source: OccupancySource.cache),
        link: RealtimeLink.reconnecting,
      ),
      offline: true,
    ),
    'sin la ocupación': ViewPartial(
      ZonesOverview(lot: lot(), layout: layout()),
      missing: const {'occupancy'},
    ),
    'sin la distribución': ViewPartial(
      ZonesOverview(lot: lot(), occupancy: occupancy()),
      missing: const {'layout'},
    ),
    'sede sin distribución': ViewData(
      ZonesOverview(lot: lot(id: 3, layoutVersion: 0)),
    ),
    'distribución sin pabellones': ViewData(
      ZonesOverview(
        lot: lot(),
        layout: const LotLayout(lotId: LotId(1), version: 4, zones: []),
        occupancy: occupancy(spaces: const []),
      ),
    ),
    'error': const ViewError(NetworkFailure()),
    'error con el contenido anterior': ViewError(
      const ServerFailure(),
      previous: overview(),
    ),
  };

  group('Zonas: estados, accesibles y sin desbordes', () {
    for (final MapEntry(key: name, value: state) in states.entries) {
      for (final (scale, dark, size) in [
        (1.0, false, const Size(360, 800)),
        (2.0, true, const Size(360, 640)),
      ]) {
        testWidgets('$name (${scale}x, ${dark ? 'oscuro' : 'claro'})', (
          tester,
        ) async {
          final handle = tester.ensureSemantics();
          await pumpPage(
            tester,
            tab(),
            state,
            textScale: scale,
            size: size,
            brightness: dark ? Brightness.dark : Brightness.light,
          );

          expect(tester.takeException(), isNull);
          await expectAccessible(tester);
          handle.dispose();
        });
      }
    }

    testWidgets('sin sede elegida pide elegirla', (tester) async {
      await pumpPage(
        tester,
        tab(),
        const ViewInitial(),
        sedeState: ViewData(SedeSelection(lots: lots)),
      );

      expect(find.text('Which campus are you heading to?'), findsOneWidget);
      expect(find.text('Sede 1'), findsOneWidget);
      expect(find.text('Pabellón A'), findsNothing);
    });
  });

  group('Zonas', () {
    testWidgets('resume la sede y dice cuántos espacios no tienen datos', (
      tester,
    ) async {
      await pumpPage(tester, tab(), ViewData(overview()));

      expect(find.text('CAPACITY'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('FREE'), findsOneWidget);
      expect(find.text('NO DATA'), findsOneWidget);
      expect(
        find.text(
          "Spaces with no data aren't counted as free until their sensor "
          'reports again.',
        ),
        findsOneWidget,
      );
      expect(find.text('Updated 20 s ago'), findsOneWidget);
    });

    testWidgets('sin espacios sin datos no hay aviso', (tester) async {
      await pumpPage(
        tester,
        tab(),
        ViewData(
          overview(
            lotOccupancy: occupancy(
              spaces: [
                for (var id = 1; id <= 8; id++)
                  state(
                    id,
                    id.isEven ? SpaceStatus.free : SpaceStatus.occupied,
                  ),
              ],
            ),
          ),
        ),
      );

      expect(find.textContaining("aren't counted as free"), findsNothing);
    });

    testWidgets('cada pabellón dice su disponibilidad con texto e ícono', (
      tester,
    ) async {
      await pumpPage(tester, tab(), ViewData(overview()));

      expect(find.text('Pabellón A'), findsOneWidget);
      expect(find.text('Edificios A–C'), findsOneWidget);
      expect(find.text('Good'), findsOneWidget);
      expect(find.text('Full'), findsOneWidget);
      expect(find.text('3 free'), findsWidgets);
      expect(find.text('1 no data'), findsOneWidget);
    });

    testWidgets('«Limitada» llega con el umbral de saturación de la sede', (
      tester,
    ) async {
      // Pabellón A: 2 ocupados y 3 libres → 40 % ocupado.
      await pumpPage(
        tester,
        tab(),
        ViewData(overview(parkingLot: lot(saturationThresholdPct: 40))),
      );

      expect(find.text('Limited'), findsOneWidget);
    });

    testWidgets('un pabellón con varios niveles abre sus niveles', (
      tester,
    ) async {
      await pumpPage(tester, tab(), ViewData(overview()));
      await tester.tap(find.text('Pabellón A'));

      expect(opened, ['zone 11']);
    });

    testWidgets('un pabellón con un solo nivel abre directo el nivel', (
      tester,
    ) async {
      await pumpPage(tester, tab(), ViewData(overview()));
      await tester.tap(find.text('Pabellón B'));

      expect(opened, ['level 12/121']);
    });

    testWidgets('«Ordenar y filtrar»: ocultar los pabellones sin libres', (
      tester,
    ) async {
      await pumpPage(tester, tab(), ViewData(overview()));
      await tester.tap(find.byTooltip('Sort and filter'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Only pavilions with free spaces'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.text('Pabellón A'), findsOneWidget);
      expect(find.text('Pabellón B'), findsNothing);
      // El filtro activo se nota en la barra.
      expect(find.byTooltip('Sort and filter, active'), findsOneWidget);
    });

    testWidgets('si el filtro oculta todo, lo dice y ofrece mostrar todos', (
      tester,
    ) async {
      await pumpPage(
        tester,
        tab(),
        ViewData(
          overview(
            lotOccupancy: occupancy(
              spaces: [
                for (var id = 1; id <= 8; id++) state(id, SpaceStatus.occupied),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Sort and filter'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Only pavilions with free spaces'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      expect(
        find.text('No pavilion has free spaces right now'),
        findsOneWidget,
      );
      await tester.tap(find.text('Show all pavilions'));
      await tester.pumpAndSettle();

      expect(find.text('Pabellón A'), findsOneWidget);
      expect(find.text('Pabellón B'), findsOneWidget);
    });

    testWidgets('con más libres primero, el pabellón lleno va al final', (
      tester,
    ) async {
      await pumpPage(tester, tab(), ViewData(overview()));
      await tester.tap(find.byTooltip('Sort and filter'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Most free spaces first'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(
        tester.getTopLeft(find.text('Pabellón A')).dy,
        lessThan(tester.getTopLeft(find.text('Pabellón B')).dy),
      );
    });

    testWidgets('el dato vencido y la falta de conexión se avisan', (
      tester,
    ) async {
      await pumpPage(
        tester,
        tab(),
        ViewData(
          overview(
            lotOccupancy: occupancy(
              age: const Duration(minutes: 25),
              source: OccupancySource.cache,
            ),
          ),
          offline: true,
        ),
      );

      expect(find.textContaining('No new data since'), findsOneWidget);
      expect(find.textContaining("You're offline"), findsOneWidget);
      expect(find.text('Offline'), findsOneWidget);
    });

    testWidgets('la antigüedad crece con el reloj monótono', (tester) async {
      await pumpPage(tester, tab(), ViewData(overview()));
      expect(find.text('Updated 20 s ago'), findsOneWidget);

      clock.advance(const Duration(seconds: 40));
      ticks.add(null);
      await tester.pump();
      await tester.pump();

      expect(find.text('Updated 1 min ago'), findsOneWidget);
    });

    testWidgets('el reintento del error vuelve a cargar', (tester) async {
      await pumpPage(tester, tab(), const ViewError(NetworkFailure()));
      await tester.tap(find.text('Try again'));

      verify(() => zones.load()).called(1);
    });

    testWidgets('en español usa el singular y «sin datos»', (tester) async {
      await pumpPage(
        tester,
        tab(),
        ViewData(overview()),
        locale: const Locale('es'),
      );

      expect(find.text('Pabellón A'), findsOneWidget);
      expect(find.text('Buena'), findsOneWidget);
      expect(find.text('Llena'), findsOneWidget);
      expect(find.text('1 sin datos'), findsOneWidget);
      expect(find.text('0 libres'), findsOneWidget);
    });
  });

  group('Pabellón', () {
    for (final MapEntry(key: name, value: state) in states.entries) {
      testWidgets('$name: accesible y sin desbordes', (tester) async {
        final handle = tester.ensureSemantics();
        await pumpPage(
          tester,
          zonePage(),
          state,
          textScale: 2,
          size: const Size(360, 640),
        );

        expect(tester.takeException(), isNull);
        await expectAccessible(tester);
        handle.dispose();
      });
    }

    testWidgets('lista sus niveles y abre el que se toca', (tester) async {
      await pumpPage(tester, zonePage(), ViewData(overview()));

      expect(find.text('Pabellón A'), findsOneWidget);
      expect(find.text('Edificios A–C'), findsOneWidget);
      expect(find.text('Levels'), findsOneWidget);
      expect(find.text('Sótano 2'), findsOneWidget);
      expect(find.text('Sótano 1'), findsOneWidget);

      await tester.tap(find.text('Sótano 1'));
      expect(opened, ['level 11/112']);
    });

    testWidgets('el botón de volver vuelve', (tester) async {
      await pumpPage(tester, zonePage(), ViewData(overview()));
      await tester.tap(find.byType(IconButton).first);

      expect(backs, 1);
    });

    testWidgets('un pabellón que ya no existe lo dice y ofrece volver', (
      tester,
    ) async {
      await pumpPage(tester, zonePage(99), ViewData(overview()));

      expect(find.text("We couldn't find this pavilion"), findsOneWidget);
      await tester.tap(find.text('Back to parking'));
      expect(backs, 1);
    });
  });

  group('Nivel', () {
    for (final MapEntry(key: name, value: state) in states.entries) {
      for (final (scale, dark) in [(1.0, false), (2.0, true)]) {
        testWidgets('$name (${scale}x): accesible y sin desbordes', (
          tester,
        ) async {
          final handle = tester.ensureSemantics();
          await pumpPage(
            tester,
            levelPage(),
            state,
            textScale: scale,
            size: scale == 1 ? const Size(360, 800) : const Size(360, 640),
            brightness: dark ? Brightness.dark : Brightness.light,
          );

          expect(tester.takeException(), isNull);
          await expectAccessible(tester);
          handle.dispose();
        });
      }
    }

    testWidgets('muestra el mapa con su leyenda y el resumen del nivel', (
      tester,
    ) async {
      await pumpPage(tester, levelPage(), ViewData(overview()));

      expect(find.text('Sótano 2'), findsOneWidget);
      expect(find.text('Pabellón A · Edificios A–C'), findsOneWidget);
      expect(find.byType(QaSpaceMap), findsOneWidget);
      expect(
        find.bySemanticsLabel('Map: 1 free, 2 occupied, 1 no data'),
        findsOneWidget,
      );
      expect(find.text('Occupied'), findsOneWidget);
    });

    testWidgets('la lista dice el estado de cada espacio y el motivo', (
      tester,
    ) async {
      await pumpPage(tester, levelPage(), ViewData(overview()));
      await tester.tap(find.text('List'));
      await tester.pumpAndSettle();

      expect(find.byType(QaSpaceMap), findsNothing);
      for (final label in ['A-01', 'A-02', 'A-03', 'A-04']) {
        expect(find.text(label), findsOneWidget);
      }
      // El espacio sin datos dice por qué (US08).
      expect(find.text('No signal from the sensor'), findsOneWidget);
      expect(find.text('No data'), findsWidgets);
    });

    testWidgets('el filtro de la lista deja solo los libres o los sin datos', (
      tester,
    ) async {
      await pumpPage(tester, levelPage(), ViewData(overview()));
      await tester.tap(find.text('List'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ChoiceChip, 'Free'));
      await tester.pumpAndSettle();
      expect(find.text('A-01'), findsOneWidget);
      expect(find.text('A-02'), findsNothing);

      await tester.tap(find.widgetWithText(ChoiceChip, 'No data'));
      await tester.pumpAndSettle();
      expect(find.text('A-03'), findsOneWidget);
      expect(find.text('A-01'), findsNothing);
    });

    testWidgets('sin posiciones no hay mapa: solo la lista y un aviso', (
      tester,
    ) async {
      await pumpPage(
        tester,
        levelPage(),
        ViewData(overview(lotLayout: layout(withPositions: false))),
      );

      expect(find.byType(QaSpaceMap), findsNothing);
      expect(
        find.text("This level doesn't have a map yet. Showing the list."),
        findsOneWidget,
      );
      expect(find.text('A-01'), findsOneWidget);
    });

    testWidgets('un nivel que ya no existe lo dice y ofrece volver', (
      tester,
    ) async {
      await pumpPage(
        tester,
        levelPage(level: 999),
        ViewData(overview()),
      );

      expect(find.text("We couldn't find this level"), findsOneWidget);
      await tester.tap(find.text('Back to parking'));
      expect(backs, 1);
    });
  });
}

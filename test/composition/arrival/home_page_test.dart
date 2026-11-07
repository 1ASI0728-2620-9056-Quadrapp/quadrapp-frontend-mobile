// US04, US05, US07, US09 a US15, US36: Inicio («Tu llegada») en cada estado,
// con las guías de accesibilidad.
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quadrapp_mobile/composition/arrival/arrival_cubit.dart';
import 'package:quadrapp_mobile/composition/arrival/arrival_state.dart';
import 'package:quadrapp_mobile/composition/arrival/home_page.dart';
import 'package:quadrapp_mobile/composition/eta/eta_cubit.dart';
import 'package:quadrapp_mobile/composition/sede/sede_cubit.dart';
import 'package:quadrapp_mobile/composition/sede/sede_state.dart';
import 'package:quadrapp_mobile/contexts/occupancy/occupancy.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/prediction_advisory.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/pump_screen.dart';

class _MockArrival extends MockCubit<ViewState<ArrivalOverview>>
    implements ArrivalCubit {}

class _MockSede extends MockCubit<ViewState<SedeSelection>>
    implements SedeCubit {}

class _MockEta extends MockCubit<EtaState> implements EtaCubit {}

ParkingLot _lot(int id, String name, {int layoutVersion = 4}) => ParkingLot(
  id: LotId(id),
  name: name,
  address: 'Av. Prueba $id',
  layoutVersion: layoutVersion,
  staleAfter: const Duration(seconds: 180),
);

final DateTime _at842 = DateTime.utc(2026, 9, 28, 13, 42);

LotOccupancy _occupancy({
  int free = 184,
  int occupied = 225,
  int unknown = 11,
  Duration age = const Duration(seconds: 40),
  OccupancySource source = OccupancySource.network,
}) => LotOccupancy(
  lotId: const LotId(1),
  capacity: free + occupied + unknown,
  free: free,
  occupied: occupied,
  unknown: unknown,
  freshness: Freshness(
    consolidatedAt: _at842,
    serverTime: _at842.add(age),
    staleAfter: const Duration(seconds: 180),
    receivedAt: Duration.zero,
  ),
  source: source,
);

ArrivalAdvice _advice(
  int eta, {
  double probability = 0.82,
  ArrivalCategory? category = ArrivalCategory.high,
  ConfidenceLevel level = ConfidenceLevel.high,
}) => ArrivalAdvice(
  etaMinutes: EtaMinutes.create(eta).valueOrNull!,
  probabilityOfSpace: probability,
  category: category,
  confidence: Confidence(value: 0.8, level: level),
  generatedAt: DateTime.utc(2026, 9, 28, 13, 40),
  serverTime: _at842,
  receivedAt: Duration.zero,
);

List<HorizonAdvice> _horizons({bool missing45 = false}) => [
  HorizonAdvice(
    ForecastHorizon.min15,
    _advice(15, probability: 0.88),
  ),
  HorizonAdvice(ForecastHorizon.min30, _advice(30)),
  HorizonAdvice(
    ForecastHorizon.min45,
    missing45
        ? null
        : _advice(
            45,
            probability: 0.61,
            category: ArrivalCategory.limited,
          ),
  ),
  HorizonAdvice(
    ForecastHorizon.min60,
    _advice(60, probability: 0.38, category: ArrivalCategory.low),
  ),
];

ArrivalOverview _overview({
  ParkingLot? lot,
  LotOccupancy? occupancy,
  ArrivalAdvice? advice,
  AdviceStatus status = AdviceStatus.available,
  List<HorizonAdvice>? horizons,
  NextAvailability? next,
  RealtimeLink? link = RealtimeLink.live,
  bool withOccupancy = true,
  AdviceChange? lastChange,
}) => ArrivalOverview(
  lot: lot ?? _lot(1, 'Monterrico'),
  occupancy: withOccupancy ? (occupancy ?? _occupancy()) : null,
  occupancyFailure: withOccupancy ? null : const NetworkFailure(),
  advice: status == AdviceStatus.available ? (advice ?? _advice(27)) : null,
  adviceStatus: status,
  horizons: horizons ?? _horizons(),
  nextAvailability: next,
  link: link,
  lastChange: lastChange,
);

EtaState _eta({
  int? minutes = 27,
  bool estimated = true,
  EtaSource? source,
  Duration? updatedAt,
  EtaIssue? issue,
  bool traffic = false,
}) => EtaState(
  estimate: minutes == null
      ? null
      : EtaEstimate(
          minutes: EtaMinutes.create(minutes).valueOrNull!,
          source: source ?? (estimated ? EtaSource.device : EtaSource.manual),
        ),
  manualMinutes: estimated ? null : minutes,
  permission: LocationPermissionStatus.granted,
  hasDestination: true,
  updatedAt: updatedAt,
  issue: issue,
  trafficAvailable: traffic,
  trafficEnabled: traffic,
);

void main() {
  late _MockArrival arrival;
  late _MockSede sede;
  late _MockEta eta;
  late FakeClock clock;
  late StreamController<void> ticks;
  var accountOpened = 0;
  var forecastOpened = 0;

  final lots = [_lot(1, 'Monterrico'), _lot(2, 'San Isidro')];

  setUpAll(() => registerFallbackValue(_lot(1, 'x')));

  setUp(() {
    arrival = _MockArrival();
    sede = _MockSede();
    eta = _MockEta();
    clock = FakeClock();
    ticks = StreamController<void>.broadcast();
    accountOpened = 0;
    forecastOpened = 0;
    when(() => arrival.setLot(any())).thenAnswer((_) async {});
    when(() => arrival.setEta(any())).thenAnswer((_) async {});
    when(() => arrival.load()).thenAnswer((_) async {});
    when(() => arrival.refresh()).thenAnswer((_) async {});
    when(() => sede.load()).thenAnswer((_) async {});
    when(() => sede.select(any())).thenAnswer((_) async {});
  });

  tearDown(() => ticks.close());

  ViewState<SedeSelection> chosen() =>
      ViewData(SedeSelection(lots: lots, selected: lots.first));

  Future<void> pumpHome(
    WidgetTester tester,
    ViewState<ArrivalOverview> state, {
    ViewState<SedeSelection>? sedeState,
    EtaState? etaState,
    Brightness brightness = Brightness.light,
    Locale locale = const Locale('en'),
    double textScale = 1,
    String? fullName = 'Camila Rojas',
    Size size = const Size(360, 2400),
  }) async {
    whenListen(
      arrival,
      const Stream<ViewState<ArrivalOverview>>.empty(),
      initialState: state,
    );
    whenListen(
      sede,
      const Stream<ViewState<SedeSelection>>.empty(),
      initialState: sedeState ?? chosen(),
    );
    whenListen(
      eta,
      const Stream<EtaState>.empty(),
      initialState: etaState ?? _eta(),
    );
    await pumpScreen(
      tester,
      MultiBlocProvider(
        providers: [
          BlocProvider<ArrivalCubit>.value(value: arrival),
          BlocProvider<SedeCubit>.value(value: sede),
          BlocProvider<EtaCubit>.value(value: eta),
        ],
        child: HomePage(
          clock: clock,
          tabIndex: 0,
          fullName: fullName,
          ticker: () => ticks.stream,
          onOpenAccount: () => accountOpened++,
          onOpenForecast: () => forecastOpened++,
        ),
      ),
      brightness: brightness,
      locale: locale,
      textScale: textScale,
      size: size,
    );
    await tester.pump();
  }

  Future<void> tick(WidgetTester tester) async {
    ticks.add(null);
    await tester.pump();
    await tester.pump();
  }

  Future<void> expectAccessible(WidgetTester tester) async {
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  }

  group('estados, accesibles y sin desbordes', () {
    final states = <String, ViewState<ArrivalOverview>>{
      'cargando (skeleton)': const ViewLoading(),
      'buena disponibilidad': ViewData(_overview()),
      'disponibilidad limitada': ViewData(
        _overview(
          advice: _advice(
            27,
            probability: 0.51,
            category: ArrivalCategory.limited,
          ),
        ),
      ),
      'lleno con la próxima liberación': ViewData(
        _overview(
          occupancy: _occupancy(free: 0, occupied: 78, unknown: 2),
          advice: _advice(27, probability: 0, category: ArrivalCategory.low),
          next: const NextAvailabilityEstimate(minMinutes: 8, maxMinutes: 15),
        ),
      ),
      'lleno sin estimación de espera': ViewData(
        _overview(
          occupancy: _occupancy(free: 0, occupied: 78, unknown: 2),
          advice: _advice(27, probability: 0, category: ArrivalCategory.low),
          next: const NextAvailabilityNoEstimate(),
        ),
      ),
      'confianza baja': ViewData(
        _overview(advice: _advice(27, level: ConfidenceLevel.low)),
      ),
      'sin tiempo de llegada': ViewData(
        _overview(status: AdviceStatus.needsEta),
      ),
      'asesoría no disponible': ViewPartial(
        _overview(status: AdviceStatus.unavailable),
        missing: const {'advice'},
      ),
      'sin la ocupación': ViewPartial(
        _overview(withOccupancy: false),
        missing: const {'occupancy'},
      ),
      'un horizonte falta': ViewPartial(
        _overview(horizons: _horizons(missing45: true)),
        missing: const {'horizons'},
      ),
      'dato vencido': ViewData(
        _overview(occupancy: _occupancy(age: const Duration(minutes: 25))),
      ),
      'sin conexión (caché)': ViewData(
        _overview(
          occupancy: _occupancy(source: OccupancySource.cache),
          link: RealtimeLink.reconnecting,
        ),
        offline: true,
      ),
      'reconectando': ViewData(_overview(link: RealtimeLink.reconnecting)),
      'sede sin distribución': ViewData(
        _overview(
          lot: _lot(3, 'San Miguel', layoutVersion: 0),
          withOccupancy: false,
          status: AdviceStatus.needsEta,
          horizons: const [],
          link: null,
        ),
      ),
      'error': const ViewError(NetworkFailure()),
      'error con el contenido anterior': ViewError(
        const ServerFailure(),
        previous: _overview(),
      ),
    };

    for (final entry in states.entries) {
      for (final (scale, dark) in [(1.0, false), (2.0, false), (1.0, true)]) {
        testWidgets(
          '${entry.key} (${scale}x${dark ? ', oscuro' : ''})',
          (tester) async {
            final handle = tester.ensureSemantics();
            await pumpHome(
              tester,
              entry.value,
              textScale: scale,
              brightness: dark ? Brightness.dark : Brightness.light,
            );

            expect(tester.takeException(), isNull);
            await expectAccessible(tester);
            handle.dispose();
          },
        );
      }
    }

    testWidgets('360×640 con texto al 200 %: sin desbordes', (tester) async {
      await pumpHome(
        tester,
        ViewData(_overview()),
        textScale: 2,
        size: const Size(360, 640),
      );

      expect(tester.takeException(), isNull);
    });

    for (final (name, sedeState) in <(String, ViewState<SedeSelection>)>[
      ('la sede cargando', const ViewLoading()),
      ('sin sede elegida', ViewData(SedeSelection(lots: lots))),
      ('la institución sin sedes', const ViewEmpty()),
      ('la lista de sedes con error', const ViewError(NetworkFailure())),
    ]) {
      testWidgets('$name: accesible y sin desbordes', (tester) async {
        final handle = tester.ensureSemantics();
        await pumpHome(
          tester,
          const ViewInitial(),
          sedeState: sedeState,
          textScale: 2,
        );

        expect(tester.takeException(), isNull);
        await expectAccessible(tester);
        handle.dispose();
      });
    }
  });

  group('encabezado', () {
    testWidgets('barra «Your arrival», saludo con el primer nombre y la '
        'pregunta', (tester) async {
      await pumpHome(tester, ViewData(_overview()));

      expect(find.text('Your arrival'), findsOneWidget);
      // 13:42 UTC son las 8:42 en Lima.
      expect(find.text('Good morning, Camila'), findsOneWidget);
      expect(find.text('Will I find a space when I arrive?'), findsOneWidget);
      expect(find.text('Monterrico'), findsOneWidget);
    });

    testWidgets('sin nombre en la sesión, saluda sin nombre', (tester) async {
      await pumpHome(tester, ViewData(_overview()), fullName: null);

      expect(find.text('Good morning'), findsOneWidget);
    });

    testWidgets('la hora de Lima decide el saludo, no la del teléfono', (
      tester,
    ) async {
      clock.wallClock = DateTime.utc(2026, 9, 28, 19);
      await pumpHome(tester, ViewData(_overview()));

      expect(find.text('Good afternoon, Camila'), findsOneWidget);
    });

    testWidgets('el perfil lleva a la cuenta', (tester) async {
      await pumpHome(tester, ViewData(_overview()));

      await tester.tap(find.byTooltip('Account'));

      expect(accountOpened, 1);
    });
  });

  group('chip de conexión (el estado real)', () {
    for (final (link, label, status) in [
      (RealtimeLink.live, 'Online', QaLiveStatus.live),
      (RealtimeLink.connecting, 'Connecting…', QaLiveStatus.reconnecting),
      (RealtimeLink.reconnecting, 'Reconnecting…', QaLiveStatus.reconnecting),
    ]) {
      testWidgets('${link.name}: «$label»', (tester) async {
        await pumpHome(tester, ViewData(_overview(link: link)));

        expect(find.text(label), findsOneWidget);
        expect(
          tester.widget<QaLiveBadge>(find.byType(QaLiveBadge)).status,
          status,
        );
      });
    }

    testWidgets('sin observación no hay chip', (tester) async {
      await pumpHome(tester, ViewData(_overview(link: null)));

      expect(find.byType(QaLiveBadge), findsNothing);
    });

    testWidgets('los datos de la caché dicen «Offline» aunque el enlace '
        'reintente', (tester) async {
      await pumpHome(
        tester,
        ViewData(
          _overview(
            occupancy: _occupancy(source: OccupancySource.cache),
            link: RealtimeLink.reconnecting,
          ),
          offline: true,
        ),
      );

      expect(find.text('Offline'), findsOneWidget);
      expect(find.text('Reconnecting…'), findsNothing);
    });
  });

  group('la tarjeta de petróleo', () {
    testWidgets('categoría, probabilidad, frase y las tres cifras', (
      tester,
    ) async {
      await pumpHome(tester, ViewData(_overview()));

      expect(find.text('Good availability'), findsOneWidget);
      // El 82 % es el de la tarjeta de petróleo y el de la ficha de 30 min.
      expect(find.text('82%'), findsNWidgets(2));
      expect(find.text("Yes, you'll probably find a space."), findsOneWidget);
      expect(find.text('ARRIVE IN'), findsOneWidget);
      expect(find.text('27 min'), findsOneWidget);
      // A qué hora llegas (con la hora del servidor) y de dónde sale.
      expect(
        find.textContaining('estimated on your phone'),
        findsOneWidget,
      );
      expect(find.textContaining('9:09'), findsOneWidget);
      expect(find.text('NOW'), findsOneWidget);
      expect(find.text('184 free'), findsOneWidget);
      // La capacidad incluye los sin datos, que van aparte.
      expect(find.text('of 420 spaces · 11 no data'), findsOneWidget);
      expect(find.text('CONFIDENCE'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
      // Toda predicción dice hace cuánto se generó (hora del servidor).
      expect(find.text('forecast 2 min ago'), findsOneWidget);
      expect(find.text('Updated 40 s ago'), findsOneWidget);
    });

    group('tu llegada se mantiene al día (US13, US14)', () {
      testWidgets(
        'dice de dónde sale, a qué hora llegas y cuándo se actualizó',
        (
          tester,
        ) async {
          clock.advance(const Duration(seconds: 90));
          await pumpHome(
            tester,
            ViewData(_overview()),
            etaState: _eta(updatedAt: Duration.zero),
          );

          expect(
            find.textContaining('estimated on your phone'),
            findsOneWidget,
          );
          expect(
            find.text('Your arrival time updated 1 min ago'),
            findsOneWidget,
          );
        },
      );

      testWidgets('recién calculado dice «just updated», no «0 s ago»', (
        tester,
      ) async {
        await pumpHome(
          tester,
          ViewData(_overview()),
          etaState: _eta(updatedAt: Duration.zero),
        );

        expect(
          find.text('Your arrival time was just updated'),
          findsOneWidget,
        );
        expect(find.textContaining('arrival time updated'), findsNothing);
      });

      testWidgets('con tráfico en vivo lo dice', (tester) async {
        await pumpHome(
          tester,
          ViewData(_overview()),
          etaState: _eta(
            source: EtaSource.traffic,
            updatedAt: Duration.zero,
            traffic: true,
          ),
        );

        expect(find.textContaining('with live traffic'), findsOneWidget);
      });

      testWidgets('un ETA elegido a mano no dice que se «actualizó»', (
        tester,
      ) async {
        await pumpHome(
          tester,
          ViewData(_overview()),
          etaState: _eta(
            minutes: 40,
            estimated: false,
            updatedAt: Duration.zero,
          ),
        );

        expect(find.textContaining('Your arrival time updated'), findsNothing);
      });

      testWidgets("con 0 minutos dice «You're here»", (tester) async {
        await pumpHome(
          tester,
          ViewData(_overview(advice: _advice(0))),
          etaState: _eta(minutes: 0),
        );

        expect(find.text("You're here"), findsOneWidget);
      });

      testWidgets('cuando la asesoría cambió dice qué cambió, con texto', (
        tester,
      ) async {
        await pumpHome(
          tester,
          ViewData(
            _overview(
              advice: _advice(
                40,
                probability: 0.55,
                category: ArrivalCategory.limited,
              ),
              lastChange: const AdviceChange(
                previousEta: 27,
                eta: 40,
                previousProbability: 0.82,
                probability: 0.55,
                previousCategory: ArrivalCategory.high,
                category: ArrivalCategory.limited,
                at: Duration.zero,
              ),
            ),
          ),
          etaState: _eta(minutes: 40),
        );

        expect(
          find.text('Updated: you arrive in 40 min (was 27)'),
          findsOneWidget,
        );
        expect(
          find.text('Chance of a space: 55% (was 82%)'),
          findsOneWidget,
        );
        expect(
          find.text('Now Limited availability (was Good availability)'),
          findsOneWidget,
        );
      });

      testWidgets('el aviso del cambio se va a los 3 minutos', (tester) async {
        await pumpHome(
          tester,
          ViewData(
            _overview(
              lastChange: const AdviceChange(
                previousEta: 27,
                eta: 24,
                previousProbability: 0.8,
                probability: 0.82,
                at: Duration.zero,
              ),
            ),
          ),
        );
        expect(find.textContaining('Updated: you arrive in'), findsOneWidget);

        clock.advance(const Duration(minutes: 3, seconds: 1));
        await tick(tester);

        expect(find.textContaining('Updated: you arrive in'), findsNothing);
      });

      testWidgets('a más de 2 horas dice por qué no hay asesoría', (
        tester,
      ) async {
        await pumpHome(
          tester,
          ViewData(_overview(status: AdviceStatus.needsEta)),
          etaState: _eta(minutes: null, issue: EtaIssue.tooFar),
        );

        expect(
          find.textContaining('more than 2 hours from campus'),
          findsOneWidget,
        );
        expect(find.text('Set arrival time'), findsOneWidget);
      });

      testWidgets('la nota de privacidad, sin el tráfico, no habla de Google', (
        tester,
      ) async {
        await pumpHome(tester, ViewData(_overview()));

        expect(
          find.text('We share arrival minutes, never your location.'),
          findsOneWidget,
        );
        expect(find.textContaining('Google'), findsNothing);
      });

      testWidgets(
        'la nota de privacidad dice la verdad con el tráfico activado',
        (
          tester,
        ) async {
          await pumpHome(
            tester,
            ViewData(_overview()),
            etaState: _eta(source: EtaSource.traffic, traffic: true),
          );

          expect(
            find.textContaining('your approximate location goes to Google'),
            findsOneWidget,
          );
          expect(
            find.text('We share arrival minutes, never your location.'),
            findsNothing,
          );
        },
      );
    });

    testWidgets('un ETA elegido por el conductor se dice «chosen by you»', (
      tester,
    ) async {
      await pumpHome(
        tester,
        ViewData(_overview()),
        etaState: _eta(minutes: 40, estimated: false),
      );

      expect(find.text('40 min'), findsOneWidget);
      expect(find.textContaining('chosen by you'), findsOneWidget);
    });

    testWidgets('disponibilidad limitada, con su frase', (tester) async {
      await pumpHome(
        tester,
        ViewData(
          _overview(
            advice: _advice(
              27,
              probability: 0.51,
              category: ArrivalCategory.limited,
            ),
          ),
        ),
      );

      expect(find.text('Limited availability'), findsWidgets);
      expect(find.text('51%'), findsOneWidget);
      expect(
        find.text("You might find a space, but it's not certain."),
        findsOneWidget,
      );
    });

    testWidgets('poca disponibilidad, con su frase', (tester) async {
      await pumpHome(
        tester,
        ViewData(
          _overview(
            advice: _advice(
              27,
              probability: 0.2,
              category: ArrivalCategory.low,
            ),
          ),
        ),
      );

      expect(find.text('Low availability'), findsOneWidget);
      expect(find.text('20%'), findsOneWidget);
      expect(find.text("You're unlikely to find a space."), findsOneWidget);
    });

    testWidgets('la confianza baja lleva su advertencia', (tester) async {
      await pumpHome(
        tester,
        ViewData(_overview(advice: _advice(27, level: ConfidenceLevel.low))),
      );

      expect(
        find.text('This estimate is based on limited information.'),
        findsOneWidget,
      );
      expect(find.text('Low'), findsOneWidget);
    });

    testWidgets('lleno: dice cuándo se espera que se libere un espacio', (
      tester,
    ) async {
      await pumpHome(
        tester,
        ViewData(
          _overview(
            occupancy: _occupancy(free: 0, occupied: 78, unknown: 2),
            next: const NextAvailabilityEstimate(minMinutes: 8, maxMinutes: 15),
          ),
        ),
      );

      expect(find.text('0 free'), findsOneWidget);
      expect(
        find.text('A space is expected to free up in 8–15 min.'),
        findsOneWidget,
      );
    });

    testWidgets('lleno sin salidas registradas: dice que no se puede '
        'estimar', (tester) async {
      await pumpHome(
        tester,
        ViewData(
          _overview(
            occupancy: _occupancy(free: 0, occupied: 78, unknown: 2),
            next: const NextAvailabilityNoEstimate(),
          ),
        ),
      );

      expect(
        find.text(
          "We can't estimate the wait: no exits were recorded recently.",
        ),
        findsOneWidget,
      );
    });

    testWidgets('con libres no hay estimación de espera', (tester) async {
      await pumpHome(tester, ViewData(_overview()));

      expect(find.textContaining('is expected to free up'), findsNothing);
    });

    testWidgets('sin tiempo de llegada pide elegirlo y abre la ventana', (
      tester,
    ) async {
      await pumpHome(
        tester,
        ViewData(_overview(status: AdviceStatus.needsEta)),
        etaState: _eta(minutes: null),
      );

      expect(
        find.text('Tell us when you arrive to estimate your availability.'),
        findsOneWidget,
      );
      expect(find.text('ARRIVE IN'), findsNothing);
      await tester.tap(find.text('Set arrival time'));
      await tester.pumpAndSettle();

      expect(find.text('When do you arrive?'), findsOneWidget);
    });

    testWidgets('tocar «Arrive in» abre «¿Cuándo llegas?»', (tester) async {
      await pumpHome(tester, ViewData(_overview()));

      await tester.tap(find.text('27 min'));
      await tester.pumpAndSettle();

      expect(find.text('When do you arrive?'), findsOneWidget);
    });

    testWidgets('la asesoría no disponible lo dice y deja ver la ocupación', (
      tester,
    ) async {
      await pumpHome(
        tester,
        ViewPartial(
          _overview(status: AdviceStatus.unavailable),
          missing: const {'advice'},
        ),
      );

      expect(
        find.text("We couldn't estimate your availability right now."),
        findsOneWidget,
      );
      expect(find.text('No estimate'), findsOneWidget);
      expect(find.text('184 free'), findsOneWidget);
      expect(
        find.text(
          "We couldn't load your arrival estimate. Pull down to try again.",
        ),
        findsOneWidget,
      );
    });

    testWidgets('sin la ocupación avisa y muestra «—» en vez de una cifra '
        'inventada', (tester) async {
      await pumpHome(
        tester,
        ViewPartial(
          _overview(withOccupancy: false),
          missing: const {'occupancy'},
        ),
      );

      expect(find.text('184 free'), findsNothing);
      expect(find.text('—'), findsOneWidget);
      expect(
        find.text(
          "We couldn't load the current spaces. Pull down to try again.",
        ),
        findsOneWidget,
      );
    });
  });

  group('«Cómo puede cambiar»', () {
    testWidgets('cuatro fichas con su porcentaje', (tester) async {
      await pumpHome(tester, ViewData(_overview()));

      expect(find.text('How it may change'), findsOneWidget);
      for (final text in ['88%', '82%', '61%', '38%']) {
        // El 82 % también es el de la tarjeta de petróleo.
        expect(find.text(text), findsWidgets);
      }
      for (final label in ['15 min', '30 min', '45 min', '60 min']) {
        expect(find.text(label), findsOneWidget);
      }
    });

    testWidgets('cada ficha se lee entera y no solo por color', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpHome(tester, ViewData(_overview()));

      expect(
        find.bySemanticsLabel('In 45 min: 61%, Limited availability'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('In 60 min: 38%, Low availability'),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('un horizonte sin asesoría se ve neutro y se anuncia', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpHome(
        tester,
        ViewPartial(
          _overview(horizons: _horizons(missing45: true)),
          missing: const {'horizons'},
        ),
      );

      expect(
        find.bySemanticsLabel('In 45 min: not available'),
        findsOneWidget,
      );
      expect(
        find.text("Some forecasts aren't available right now."),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('tocar una ficha abre la predicción', (tester) async {
      await pumpHome(tester, ViewData(_overview()));

      await tester.tap(find.text('88%'));

      expect(forecastOpened, 1);
    });
  });

  group('avisos', () {
    testWidgets('dato vencido: aviso con la hora y la antigüedad del dato', (
      tester,
    ) async {
      await pumpHome(
        tester,
        ViewData(
          _overview(occupancy: _occupancy(age: const Duration(minutes: 25))),
        ),
      );

      expect(
        find.textContaining('No new data since 8:42'),
        findsOneWidget,
      );
      expect(find.text('Updated 25 min ago'), findsOneWidget);
    });

    testWidgets('un dato fresco vence al pasar el tiempo, con el reloj local', (
      tester,
    ) async {
      await pumpHome(tester, ViewData(_overview()));
      expect(find.textContaining('No new data since'), findsNothing);
      expect(find.text('Updated 40 s ago'), findsOneWidget);

      // Un reloj de pared desfasado no cambia nada.
      clock.wallClock = DateTime.utc(2030);
      await tick(tester);
      expect(find.text('Updated 40 s ago'), findsOneWidget);

      // El tiempo transcurrido localmente sí suma a la antigüedad.
      clock.advance(const Duration(seconds: 170));
      await tick(tester);
      expect(find.textContaining('No new data since'), findsOneWidget);
    });

    testWidgets('sin conexión: aviso arriba con lo último que hay', (
      tester,
    ) async {
      await pumpHome(
        tester,
        ViewData(
          _overview(occupancy: _occupancy(source: OccupancySource.cache)),
          offline: true,
        ),
      );

      expect(
        find.text("You're offline. Showing the latest data we have."),
        findsOneWidget,
      );
    });

    testWidgets('error con el contenido anterior: aviso con reintentar', (
      tester,
    ) async {
      await pumpHome(
        tester,
        ViewError(const ServerFailure(), previous: _overview()),
      );

      expect(
        find.text('Something went wrong on our side. Try again in a moment.'),
        findsOneWidget,
      );
      await tester.tap(find.text('Try again'));
      verify(() => arrival.load()).called(1);
      expect(find.text('Good availability'), findsOneWidget);
    });
  });

  group('otros estados', () {
    testWidgets('cargando: skeletons con su etiqueta, sin spinners', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpHome(tester, const ViewLoading());

      expect(find.byType(QaSkeleton), findsWidgets);
      expect(find.bySemanticsLabel('Loading parking lots…'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      handle.dispose();
    });

    testWidgets('error: causa y salida; reintentar vuelve a cargar', (
      tester,
    ) async {
      await pumpHome(tester, const ViewError(NetworkFailure()));

      expect(find.text("Couldn't load parking lots"), findsOneWidget);
      expect(
        find.text("You're offline. Check your connection and try again."),
        findsOneWidget,
      );
      await tester.tap(find.text('Try again'));

      verify(() => arrival.load()).called(1);
    });

    testWidgets('la institución sin sedes: estado vacío honesto', (
      tester,
    ) async {
      await pumpHome(
        tester,
        const ViewInitial(),
        sedeState: const ViewEmpty(),
      );

      expect(find.text('No parking lots yet'), findsOneWidget);
    });

    testWidgets('la lista de sedes con error ofrece reintentar', (
      tester,
    ) async {
      await pumpHome(
        tester,
        const ViewInitial(),
        sedeState: const ViewError(NetworkFailure()),
      );

      expect(find.text("Couldn't load the campuses"), findsOneWidget);
      await tester.tap(find.text('Try again'));

      verify(() => sede.load()).called(1);
    });

    testWidgets('sin sede elegida pide elegirla', (tester) async {
      await pumpHome(
        tester,
        const ViewInitial(),
        sedeState: ViewData(SedeSelection(lots: lots)),
      );

      expect(find.text('Which campus are you heading to?'), findsOneWidget);
      await tester.tap(find.text('San Isidro'));
      verify(() => sede.select(const LotId(2))).called(1);
    });

    testWidgets('una sede sin distribución se presenta sin disponibilidad y '
        'sin la tarjeta de petróleo (US04 esc. 2)', (tester) async {
      await pumpHome(
        tester,
        ViewData(
          _overview(
            lot: _lot(3, 'San Miguel', layoutVersion: 0),
            withOccupancy: false,
            status: AdviceStatus.needsEta,
            horizons: const [],
            link: null,
          ),
        ),
      );

      expect(find.text('San Miguel · No current data'), findsOneWidget);
      expect(find.text('Choose another campus'), findsOneWidget);
      expect(find.text('ARRIVE IN'), findsNothing);
      expect(find.text('How it may change'), findsNothing);
      expect(find.byType(QaLiveBadge), findsNothing);
    });
  });

  group('sede, ETA y recarga', () {
    testWidgets('al abrir sincroniza la sede elegida y el ETA con el cubit', (
      tester,
    ) async {
      await pumpHome(tester, ViewData(_overview()));
      await tester.pump();

      verify(() => arrival.setLot(lots.first)).called(1);
      verify(() => arrival.setEta(27)).called(1);
    });

    testWidgets('deslizar hacia abajo recarga', (tester) async {
      await pumpHome(
        tester,
        ViewData(_overview()),
        size: const Size(360, 800),
      );

      await tester.fling(
        find.byType(CustomScrollView),
        const Offset(0, 300),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      verify(() => arrival.refresh()).called(1);
    });
  });

  testWidgets('en español', (tester) async {
    await pumpHome(
      tester,
      ViewData(_overview()),
      locale: const Locale('es'),
    );

    expect(find.text('Tu llegada'), findsOneWidget);
    expect(find.text('Buenos días, Camila'), findsOneWidget);
    expect(find.text('¿Encontraré espacio al llegar?'), findsOneWidget);
    expect(find.text('En línea'), findsOneWidget);
    expect(find.text('Buena disponibilidad'), findsOneWidget);
    expect(
      find.text('Sí, es probable que encuentres espacio.'),
      findsOneWidget,
    );
    expect(find.text('LLEGAS EN'), findsOneWidget);
    expect(find.textContaining('estimado en tu teléfono'), findsOneWidget);
    expect(find.text('184 libres'), findsOneWidget);
    expect(find.text('de 420 espacios · 11 sin datos'), findsOneWidget);
    expect(find.text('Alta'), findsOneWidget);
    expect(find.text('predicción hace 2 min'), findsOneWidget);
    expect(find.text('Cómo puede cambiar'), findsOneWidget);
    expect(
      find.text('Compartimos minutos de llegada, nunca tu ubicación.'),
      findsOneWidget,
    );
  });
}

// US04, US09, US10, US11, US12, US13, US15: Predicción en cada estado, con las
// guías de accesibilidad.
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quadrapp_mobile/composition/eta/eta_cubit.dart';
import 'package:quadrapp_mobile/composition/forecast/forecast_cubit.dart';
import 'package:quadrapp_mobile/composition/forecast/forecast_row_card.dart';
import 'package:quadrapp_mobile/composition/forecast/forecast_state.dart';
import 'package:quadrapp_mobile/composition/forecast/forecast_tab_page.dart';
import 'package:quadrapp_mobile/composition/sede/sede_cubit.dart';
import 'package:quadrapp_mobile/composition/sede/sede_state.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/prediction_advisory.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/pump_screen.dart';
import 'support.dart';

class _MockForecast extends MockCubit<ViewState<ForecastOverview>>
    implements ForecastCubit {}

class _MockSede extends MockCubit<ViewState<SedeSelection>>
    implements SedeCubit {}

class _MockEta extends MockCubit<EtaState> implements EtaCubit {}

EtaState _eta({
  int? minutes = 27,
  bool estimated = true,
  EtaSource? source,
  Duration? updatedAt,
  EtaIssue? issue,
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
);

void main() {
  late _MockForecast forecastCubit;
  late _MockSede sede;
  late _MockEta eta;
  late FakeClock clock;
  late StreamController<void> ticks;

  final lots = [lot(), lot(id: 2)];

  setUpAll(() => registerFallbackValue(lot()));

  setUp(() {
    forecastCubit = _MockForecast();
    sede = _MockSede();
    eta = _MockEta();
    clock = FakeClock();
    ticks = StreamController<void>.broadcast();
    when(() => forecastCubit.setLot(any())).thenAnswer((_) async {});
    when(() => forecastCubit.load()).thenAnswer((_) async {});
    when(() => forecastCubit.refresh()).thenAnswer((_) async {});
    when(() => sede.load()).thenAnswer((_) async {});
    when(() => sede.select(any())).thenAnswer((_) async {});
  });

  tearDown(() => ticks.close());

  Future<void> pumpPage(
    WidgetTester tester,
    ViewState<ForecastOverview> state, {
    ViewState<SedeSelection>? sedeState,
    EtaState? etaState,
    Brightness brightness = Brightness.light,
    Locale locale = const Locale('en'),
    double textScale = 1,
    Size size = const Size(360, 2000),
  }) async {
    whenListen(
      forecastCubit,
      const Stream<ViewState<ForecastOverview>>.empty(),
      initialState: state,
    );
    whenListen(
      sede,
      const Stream<ViewState<SedeSelection>>.empty(),
      initialState:
          sedeState ??
          ViewData(SedeSelection(lots: lots, selected: lots.first)),
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
          BlocProvider<ForecastCubit>.value(value: forecastCubit),
          BlocProvider<SedeCubit>.value(value: sede),
          BlocProvider<EtaCubit>.value(value: eta),
        ],
        child: ForecastTabPage(
          clock: clock,
          tabIndex: 2,
          ticker: () => ticks.stream,
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

  final states = <String, ViewState<ForecastOverview>>{
    'cargando (skeleton)': const ViewLoading(),
    'con datos': ViewData(overview()),
    'confianza baja en el horizonte lejano': ViewData(
      overview(
        lotForecasts: forecasts(
          overrides: {
            ForecastHorizon.min60: forecast(
              ForecastHorizon.min60,
              confidence: 0.38,
              level: ConfidenceLevel.low,
            ),
          },
        ),
      ),
    ),
    'estimación de contingencia': ViewData(
      overview(
        lotForecasts: forecasts(
          overrides: {
            for (final horizon in ForecastHorizon.values)
              horizon: forecast(
                horizon,
                confidence: 0.2,
                level: ConfidenceLevel.low,
                method: ForecastMethod.fallback,
              ),
          },
        ),
      ),
    ),
    'un horizonte falta': ViewData(
      overview(lotForecasts: forecasts(missing: {ForecastHorizon.min45})),
    ),
    'un pronóstico venció': ViewData(
      overview(
        lotForecasts: forecasts(
          overrides: {
            ForecastHorizon.min15: forecast(
              ForecastHorizon.min15,
              validFor: Duration.zero,
            ),
          },
        ),
      ),
    ),
    'saturación prevista': ViewData(
      overview(
        lotForecasts: forecasts(
          overrides: {
            ForecastHorizon.min30: forecast(
              ForecastHorizon.min30,
              expected: 96,
              saturation: Saturation(
                expectedAt: t0.add(const Duration(minutes: 25)),
                pct: 95,
              ),
            ),
          },
        ),
      ),
    ),
    'sin el detalle de los pronósticos': ViewPartial(
      overview(withForecasts: false),
      missing: const {'forecasts'},
    ),
    'sin pronósticos en ningún horizonte': ViewData(
      overview(
        lotForecasts: const LotForecasts([]),
        lotAdvices: advices(missing: ForecastHorizon.values.toSet()),
      ),
    ),
    'sede sin distribución': ViewData(
      overview(parkingLot: lot(id: 3, layoutVersion: 0)),
    ),
    'error': const ViewError(NetworkFailure()),
    'error con el contenido anterior': ViewError(
      const ServerFailure(),
      previous: overview(),
    ),
  };

  group('estados, accesibles y sin desbordes', () {
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

    testWidgets('sin tiempo de llegada, la tarjeta invita a elegirlo', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpPage(
        tester,
        ViewData(overview()),
        etaState: _eta(minutes: null),
      );

      expect(find.text('Pick when you arrive'), findsOneWidget);
      expect(find.text('Your arrival'), findsOneWidget);
      await expectAccessible(tester);
      handle.dispose();
    });

    testWidgets('sin sede elegida pide elegirla', (tester) async {
      await pumpPage(
        tester,
        const ViewInitial(),
        sedeState: ViewData(SedeSelection(lots: lots)),
      );

      expect(find.text('Which campus are you heading to?'), findsOneWidget);
      expect(find.text('15 min'), findsNothing);
    });
  });

  group('contenido', () {
    testWidgets('el tiempo de llegada, los cuatro horizontes y la nota', (
      tester,
    ) async {
      await pumpPage(tester, ViewData(overview()));

      expect(find.text('If you leave now'), findsOneWidget);
      expect(find.text('You arrive in 27 min'), findsOneWidget);
      expect(find.text('Estimated on your phone'), findsOneWidget);
      for (final text in ['15 min', '30 min', '45 min', '60 min']) {
        expect(find.text(text), findsOneWidget);
      }
      for (final text in ['88%', '82%', '61%', '38%']) {
        expect(find.text(text), findsOneWidget);
      }
      expect(find.text('Good availability'), findsNWidgets(2));
      expect(find.text('Limited availability'), findsOneWidget);
      expect(find.text('Low availability'), findsOneWidget);
      expect(
        find.text(
          'Estimate based on historical occupancy, flow, the academic '
          'calendar and events.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('con tráfico en vivo lo dice y cuándo se actualizó', (
      tester,
    ) async {
      clock.advance(const Duration(seconds: 150));
      await pumpPage(
        tester,
        ViewData(overview()),
        etaState: _eta(source: EtaSource.traffic, updatedAt: Duration.zero),
      );

      expect(find.text('With live traffic'), findsOneWidget);
      expect(
        find.text('Your arrival time updated 2 min ago'),
        findsOneWidget,
      );
    });

    testWidgets('a mano no dice que se «actualizó»', (tester) async {
      await pumpPage(
        tester,
        ViewData(overview()),
        etaState: _eta(
          minutes: 40,
          estimated: false,
          updatedAt: Duration.zero,
        ),
      );

      expect(find.textContaining('Your arrival time updated'), findsNothing);
    });

    testWidgets('a más de 2 horas dice por qué no hay tiempo de llegada', (
      tester,
    ) async {
      await pumpPage(
        tester,
        ViewData(overview()),
        etaState: _eta(minutes: null, issue: EtaIssue.tooFar),
      );

      expect(find.text('More than 2 hours away'), findsOneWidget);
      expect(find.text('Pick when you arrive'), findsOneWidget);
    });

    testWidgets('con el tiempo elegido a mano lo dice', (tester) async {
      await pumpPage(
        tester,
        ViewData(overview()),
        etaState: _eta(minutes: 40, estimated: false),
      );

      expect(find.text('Your arrival time'), findsOneWidget);
      expect(find.text('You arrive in 40 min'), findsOneWidget);
      expect(find.text('Set by you'), findsOneWidget);
    });

    testWidgets('marca el horizonte más cercano al tiempo de llegada', (
      tester,
    ) async {
      await pumpPage(tester, ViewData(overview()), etaState: _eta());

      // 27 min queda más cerca de 30 que de 15.
      expect(find.text('Your arrival'), findsOneWidget);
      final card = find.ancestor(
        of: find.text('Your arrival'),
        matching: find.byType(ForecastRowCard),
      );
      expect(card, findsOneWidget);
      expect(
        find.descendant(of: card, matching: find.text('30 min')),
        findsOneWidget,
      );
    });

    testWidgets('cada horizonte dice su confianza y cuándo se generó', (
      tester,
    ) async {
      await pumpPage(tester, ViewData(overview()));

      expect(find.text('Confidence: High'), findsNWidgets(4));
      // Generados hace 2 min, a las 8:40 AM en Lima.
      expect(find.textContaining('Generated at 8:40'), findsOneWidget);
      expect(find.textContaining('· 2 min ago'), findsOneWidget);
    });

    testWidgets(
      'la confianza baja se ve en su horizonte, sin culpar al historial',
      (
        tester,
      ) async {
        await pumpPage(
          tester,
          ViewData(
            overview(
              lotForecasts: forecasts(
                overrides: {
                  ForecastHorizon.min60: forecast(
                    ForecastHorizon.min60,
                    confidence: 0.38,
                    level: ConfidenceLevel.low,
                  ),
                },
              ),
            ),
          ),
        );

        expect(find.text('Confidence: Low'), findsOneWidget);
        expect(find.textContaining('little history'), findsNothing);
      },
    );

    testWidgets('la estimación de contingencia avisa que hay poco historial', (
      tester,
    ) async {
      await pumpPage(
        tester,
        ViewData(
          overview(
            lotForecasts: forecasts(
              overrides: {
                for (final horizon in ForecastHorizon.values)
                  horizon: forecast(
                    horizon,
                    confidence: 0.2,
                    level: ConfidenceLevel.low,
                    method: ForecastMethod.fallback,
                  ),
              },
            ),
          ),
        ),
      );

      expect(
        find.text(
          'There is little history for this lot. Treat these numbers as a '
          'rough guide.',
        ),
        findsOneWidget,
      );
      expect(find.text('Confidence: Low'), findsNWidgets(4));
    });

    testWidgets('un horizonte faltante se indica y no se inventa su cifra', (
      tester,
    ) async {
      await pumpPage(
        tester,
        ViewData(
          overview(lotForecasts: forecasts(missing: {ForecastHorizon.min45})),
        ),
      );

      expect(find.text('No forecast for this time'), findsOneWidget);
      expect(find.text('61%'), findsNothing);
      expect(
        find.text('Some forecasts are missing. Showing the ones we have.'),
        findsOneWidget,
      );
      expect(find.text('88%'), findsOneWidget);
    });

    testWidgets('un pronóstico vence con la pantalla abierta (US10 esc. 3)', (
      tester,
    ) async {
      await pumpPage(
        tester,
        ViewData(
          overview(
            lotForecasts: forecasts(
              overrides: {
                ForecastHorizon.min15: forecast(
                  ForecastHorizon.min15,
                  validFor: const Duration(minutes: 5),
                ),
              },
            ),
          ),
        ),
      );
      expect(find.text('88%'), findsOneWidget);
      expect(find.text('Forecast expired'), findsNothing);

      clock.advance(const Duration(minutes: 6));
      await tick(tester);

      expect(find.text('88%'), findsNothing);
      expect(find.text('Forecast expired'), findsOneWidget);
      expect(
        find.text(
          "Some forecasts have expired, so they aren't shown as current.",
        ),
        findsOneWidget,
      );
    });

    testWidgets('sin el detalle, avisa y muestra las probabilidades', (
      tester,
    ) async {
      await pumpPage(
        tester,
        ViewPartial(
          overview(withForecasts: false),
          missing: const {'forecasts'},
        ),
      );

      expect(
        find.text(
          "We couldn't load the forecast details. Showing the arrival odds.",
        ),
        findsOneWidget,
      );
      expect(find.text('88%'), findsOneWidget);
      await tester.tap(find.text('Try again'));
      verify(() => forecastCubit.load()).called(1);
    });

    testWidgets(
      'sin pronósticos, estado vacío con la salida de elegir otra sede',
      (
        tester,
      ) async {
        await pumpPage(
          tester,
          ViewData(
            overview(
              lotForecasts: const LotForecasts([]),
              lotAdvices: advices(missing: ForecastHorizon.values.toSet()),
            ),
          ),
        );

        expect(find.text('No forecasts yet'), findsOneWidget);
        expect(find.text('Choose another campus'), findsOneWidget);
        expect(find.text('15 min'), findsNothing);
      },
    );

    testWidgets('el reintento del error vuelve a cargar', (tester) async {
      await pumpPage(tester, const ViewError(NetworkFailure()));
      await tester.tap(find.text('Try again'));

      verify(() => forecastCubit.load()).called(1);
    });

    testWidgets('en español', (tester) async {
      await pumpPage(
        tester,
        ViewData(overview()),
        locale: const Locale('es'),
      );

      expect(find.text('Predicción'), findsOneWidget);
      expect(find.text('Si sales ahora'), findsOneWidget);
      expect(find.text('Llegas en 27 min'), findsOneWidget);
      expect(find.text('Estimado en tu teléfono'), findsOneWidget);
      expect(find.text('Buena disponibilidad'), findsNWidgets(2));
      expect(find.text('Confianza: Alta'), findsNWidgets(4));
      expect(find.textContaining('Generada a las 8:40'), findsOneWidget);
      expect(find.textContaining('· hace 2 min'), findsOneWidget);
    });
  });

  group('detalle', () {
    testWidgets('abre el detalle del horizonte con la ocupación esperada', (
      tester,
    ) async {
      await pumpPage(tester, ViewData(overview()));
      await tester.tap(find.text('30 min'));
      await tester.pumpAndSettle();

      expect(find.text('Forecast in 30 min'), findsOneWidget);
      expect(find.text('82%'), findsWidgets);
      expect(find.text('Chance of finding a space'), findsOneWidget);
      expect(find.text('Expected occupancy'), findsOneWidget);
      expect(find.text('72%'), findsOneWidget);
      expect(find.text('Not expected to fill up'), findsOneWidget);
      expect(find.text('Generated'), findsOneWidget);
      expect(find.text('13 more min'), findsOneWidget);
      expect(find.text('Main model'), findsOneWidget);
      expect(find.text('Model m-2026.09'), findsOneWidget);
    });

    testWidgets('con saturación prevista, dice el momento y el porcentaje', (
      tester,
    ) async {
      await pumpPage(
        tester,
        ViewData(
          overview(
            lotForecasts: forecasts(
              overrides: {
                ForecastHorizon.min30: forecast(
                  ForecastHorizon.min30,
                  expected: 96,
                  saturation: Saturation(
                    expectedAt: t0.add(const Duration(minutes: 25)),
                    pct: 95,
                  ),
                ),
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('30 min'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Expected to fill up at 9:07'),
        findsOneWidget,
      );
      expect(find.textContaining('(95%)'), findsOneWidget);
    });

    testWidgets('con confianza baja, advierte sin traducirla a una categoría', (
      tester,
    ) async {
      await pumpPage(
        tester,
        ViewData(
          overview(
            lotForecasts: forecasts(
              overrides: {
                ForecastHorizon.min60: forecast(
                  ForecastHorizon.min60,
                  confidence: 0.38,
                  level: ConfidenceLevel.low,
                  method: ForecastMethod.fallback,
                ),
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('60 min'));
      await tester.pumpAndSettle();

      expect(
        find.text('Contingency estimate (limited history)'),
        findsOneWidget,
      );
      expect(
        find.text(
          'This forecast relies on limited information. Use it as a reference.',
        ),
        findsOneWidget,
      );
      expect(find.text('Confidence: Low'), findsWidgets);
    });

    testWidgets('un pronóstico vencido o faltante lo dice en su detalle', (
      tester,
    ) async {
      await pumpPage(
        tester,
        ViewData(
          overview(
            lotForecasts: forecasts(
              missing: {ForecastHorizon.min45},
              overrides: {
                ForecastHorizon.min15: forecast(
                  ForecastHorizon.min15,
                  validFor: Duration.zero,
                ),
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('15 min'));
      await tester.pumpAndSettle();
      expect(
        find.text("This forecast has expired and isn't shown as current."),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('45 min'));
      await tester.pumpAndSettle();
      expect(
        find.text('There is no forecast for this time yet.'),
        findsOneWidget,
      );
    });
  });

  group('tiempo de llegada', () {
    testWidgets('la tarjeta abre «¿Cuándo llegas?»', (tester) async {
      await pumpPage(tester, ViewData(overview()));
      await tester.tap(find.text('You arrive in 27 min'));
      await tester.pumpAndSettle();

      expect(find.text('When do you arrive?'), findsWidgets);
    });

    testWidgets('el calendario de la barra abre «¿Cuándo llegas?»', (
      tester,
    ) async {
      await pumpPage(tester, ViewData(overview()));
      await tester.tap(find.byTooltip('Choose your arrival time'));
      await tester.pumpAndSettle();

      expect(find.text('When do you arrive?'), findsWidgets);
    });
  });
}

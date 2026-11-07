@Tags(['screenshots'])
library;

// Capturas del Inicio en los estados del tiempo de llegada que la app con
// mocks no muestra sin esperar minutos: la asesoría que cambió al cambiar el
// ETA (US14) y el conductor a más de 2 horas del campus (US13 esc. 2):
//   flutter test --tags screenshots --run-skipped --update-goldens
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
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

import '../helpers/fake_clock.dart';
import '../helpers/pump_screen.dart';
import 'screenshot_support.dart';

class _MockArrival extends MockCubit<ViewState<ArrivalOverview>>
    implements ArrivalCubit {}

class _MockSede extends MockCubit<ViewState<SedeSelection>>
    implements SedeCubit {}

class _MockEta extends MockCubit<EtaState> implements EtaCubit {}

final DateTime _at = DateTime.utc(2026, 9, 28, 13, 42);

ParkingLot _lot() => const ParkingLot(
  id: LotId(1),
  name: 'Monterrico',
  layoutVersion: 4,
  staleAfter: Duration(seconds: 180),
);

ArrivalAdvice _advice(
  int eta,
  double probability,
  ArrivalCategory category,
) => ArrivalAdvice(
  etaMinutes: EtaMinutes.create(eta).valueOrNull!,
  probabilityOfSpace: probability,
  category: category,
  confidence: const Confidence(value: 0.8, level: ConfidenceLevel.high),
  generatedAt: _at.subtract(const Duration(minutes: 2)),
  serverTime: _at,
  receivedAt: Duration.zero,
);

LotOccupancy _occupancy() => LotOccupancy(
  lotId: const LotId(1),
  capacity: 120,
  free: 45,
  occupied: 72,
  unknown: 3,
  freshness: Freshness(
    consolidatedAt: _at.subtract(const Duration(seconds: 20)),
    serverTime: _at,
    staleAfter: const Duration(seconds: 180),
    receivedAt: Duration.zero,
  ),
);

List<HorizonAdvice> _horizons() => [
  HorizonAdvice(
    ForecastHorizon.min15,
    _advice(15, 0.88, ArrivalCategory.high),
  ),
  HorizonAdvice(
    ForecastHorizon.min30,
    _advice(30, 0.76, ArrivalCategory.high),
  ),
  HorizonAdvice(
    ForecastHorizon.min45,
    _advice(45, 0.52, ArrivalCategory.limited),
  ),
  HorizonAdvice(
    ForecastHorizon.min60,
    _advice(60, 0.27, ArrivalCategory.low),
  ),
];

void main() {
  setUpAll(loadAppFonts);

  Future<void> shoot(
    WidgetTester tester,
    String name,
    Shot shot, {
    required ArrivalOverview overview,
    required EtaState eta,
  }) async {
    final arrival = _MockArrival();
    final sede = _MockSede();
    final etaCubit = _MockEta();
    when(() => arrival.setLot(any())).thenAnswer((_) async {});
    when(() => arrival.setEta(any())).thenAnswer((_) async {});
    when(sede.load).thenAnswer((_) async {});
    whenListen(
      arrival,
      const Stream<ViewState<ArrivalOverview>>.empty(),
      initialState: ViewData(overview),
    );
    whenListen(
      sede,
      const Stream<ViewState<SedeSelection>>.empty(),
      initialState: ViewData(
        SedeSelection(lots: [_lot()], selected: _lot()),
      ),
    );
    whenListen(
      etaCubit,
      const Stream<EtaState>.empty(),
      initialState: eta,
    );
    await pumpScreen(
      tester,
      MultiBlocProvider(
        providers: [
          BlocProvider<ArrivalCubit>.value(value: arrival),
          BlocProvider<SedeCubit>.value(value: sede),
          BlocProvider<EtaCubit>.value(value: etaCubit),
        ],
        child: HomePage(
          clock: FakeClock(),
          tabIndex: 0,
          fullName: 'Camila Rojas',
          ticker: () => const Stream<void>.empty(),
          onOpenAccount: () {},
          onOpenForecast: () {},
        ),
      ),
      size: Size(shot.size.width.toDouble(), shot.size.height.toDouble()),
      brightness: shot.brightness,
      textScale: shot.textScale,
      pixelRatio: 2,
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../docs/screenshots/${name}_${shot.label}.png'),
    );
  }

  setUpAll(() {
    registerFallbackValue(_lot());
  });

  final base = ArrivalOverview(
    lot: _lot(),
    occupancy: _occupancy(),
    horizons: _horizons(),
    adviceStatus: AdviceStatus.available,
  );

  for (final shot in [standardShots.first, standardShots[2]]) {
    testWidgets('home_change ${shot.label}', (tester) async {
      await withRealShadows(
        () => shoot(
          tester,
          'home_change',
          shot,
          overview: ArrivalOverview(
            lot: _lot(),
            occupancy: _occupancy(),
            advice: _advice(40, 0.52, ArrivalCategory.limited),
            adviceStatus: AdviceStatus.available,
            horizons: _horizons(),
            lastChange: const AdviceChange(
              previousEta: 27,
              eta: 40,
              previousProbability: 0.76,
              probability: 0.52,
              previousCategory: ArrivalCategory.high,
              category: ArrivalCategory.limited,
              at: Duration.zero,
            ),
          ),
          eta: EtaState(
            estimate: EtaEstimate(
              minutes: EtaMinutes.create(40).valueOrNull!,
              source: EtaSource.traffic,
            ),
            permission: LocationPermissionStatus.granted,
            hasDestination: true,
            trafficAvailable: true,
            trafficEnabled: true,
            updatedAt: Duration.zero,
          ),
        ),
      );
    });

    testWidgets('home_toofar ${shot.label}', (tester) async {
      await withRealShadows(
        () => shoot(
          tester,
          'home_toofar',
          shot,
          overview: base
              .copyWith(clearAdvice: true)
              .copyWith(
                adviceStatus: AdviceStatus.needsEta,
              ),
          eta: const EtaState(
            permission: LocationPermissionStatus.granted,
            hasDestination: true,
            issue: EtaIssue.tooFar,
            updatedAt: Duration.zero,
          ),
        ),
      );
    });
  }
}

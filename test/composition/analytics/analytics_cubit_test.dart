// US21, US22, US34: el cubit de Analítica y el riesgo del pronóstico.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quadrapp_mobile/composition/analytics/analytics_cubit.dart';
import 'package:quadrapp_mobile/composition/analytics/analytics_overview.dart';
import 'package:quadrapp_mobile/contexts/analytics/analytics.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/prediction_advisory.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

import '../../helpers/fake_clock.dart';

class _MockHistory extends Mock implements GetOccupancyHistory {}

class _MockPeaks extends Mock implements GetPeakHours {}

class _MockAccuracy extends Mock implements GetForecastAccuracy {}

class _MockForecasts extends Mock implements GetLotForecasts {}

class _MockExport extends Mock implements ExportAnalyticsReport {}

const LotId _lot = LotId(1);
final AnalyticsRange _anyRange = AnalyticsRange.of(
  DateTime.utc(2026),
  DateTime.utc(2026, 2),
)!;

OccupancyHistory _history(OccupancyHistoryQuery query) => OccupancyHistory(
  lotId: query.lotId,
  zoneId: query.zoneId,
  range: query.range,
  granularity: OccupancyGranularity.forLength(query.range.length),
  serverTime: query.range.to,
  points: [OccupancyPoint(at: query.range.from, occupancyPct: 50)],
);

Forecast _forecast(ForecastHorizon horizon, double pct, DateTime now) =>
    Forecast(
      horizon: horizon,
      expectedOccupancyPct: pct,
      confidence: const Confidence(value: 0.84, level: ConfidenceLevel.high),
      modelVersion: 'v3.0',
      method: ForecastMethod.primaryModel,
      generatedAt: now,
      validity: ForecastValidity(
        validUntil: now.add(const Duration(minutes: 10)),
        serverTime: now,
        receivedAt: Duration.zero,
      ),
    );

void main() {
  late FakeClock clock;
  late _MockHistory history;
  late _MockPeaks peaks;
  late _MockAccuracy accuracy;
  late _MockForecasts forecasts;
  late _MockExport export;

  setUpAll(() {
    registerFallbackValue((lotId: _lot, range: _anyRange, zoneId: null));
    registerFallbackValue((lotId: _lot, range: _anyRange));
    registerFallbackValue(_lot);
  });

  setUp(() {
    clock = FakeClock();
    history = _MockHistory();
    peaks = _MockPeaks();
    accuracy = _MockAccuracy();
    forecasts = _MockForecasts();
    export = _MockExport();
    when(() => history(any())).thenAnswer(
      (invocation) async => Success(
        _history(invocation.positionalArguments.first as OccupancyHistoryQuery),
      ),
    );
    when(() => peaks(any())).thenAnswer(
      (_) async => Success(PeakHours(sufficientData: false, peaks: const [])),
    );
    when(() => accuracy(any())).thenAnswer(
      (_) async => Success(ForecastAccuracy(const [])),
    );
    when(() => forecasts(any())).thenAnswer(
      (_) async => const Success(LotForecasts([])),
    );
  });

  AnalyticsCubit build() => AnalyticsCubit(
    getOccupancyHistory: history,
    getPeakHours: peaks,
    getForecastAccuracy: accuracy,
    getLotForecasts: forecasts,
    exportReport: export,
    clock: clock,
  );

  blocTest<AnalyticsCubit, ViewState<AnalyticsOverview>>(
    'abre en 30 días, por día y sin pedir el pronóstico',
    build: build,
    act: (cubit) => cubit.load(_lot),
    expect: () => [
      isA<ViewLoading<AnalyticsOverview>>(),
      isA<ViewData<AnalyticsOverview>>()
          .having((s) => s.data.period, 'period', AnalyticsPeriod.last30Days)
          .having(
            (s) => s.data.history!.granularity,
            'granularity',
            OccupancyGranularity.day,
          ),
    ],
    verify: (_) => verifyNever(() => forecasts(any())),
  );

  blocTest<AnalyticsCubit, ViewState<AnalyticsOverview>>(
    'hoy, por hora y con el pronóstico del estacionamiento',
    build: build,
    act: (cubit) async {
      await cubit.load(_lot);
      await cubit.selectPeriod(AnalyticsPeriod.today);
    },
    skip: 2,
    expect: () => [
      isA<ViewLoading<AnalyticsOverview>>(),
      isA<ViewData<AnalyticsOverview>>()
          .having((s) => s.data.showsForecast, 'showsForecast', isTrue)
          .having((s) => s.data.forecasts, 'forecasts', isNotNull)
          .having(
            (s) => s.data.history!.granularity,
            'granularity',
            OccupancyGranularity.hour,
          ),
    ],
  );

  blocTest<AnalyticsCubit, ViewState<AnalyticsOverview>>(
    'una parte que falla deja la respuesta parcial',
    setUp: () => when(
      () => peaks(any()),
    ).thenAnswer((_) async => const Err(ServerFailure())),
    build: build,
    act: (cubit) => cubit.load(_lot),
    skip: 1,
    expect: () => [
      isA<ViewPartial<AnalyticsOverview>>()
          .having((s) => s.missing, 'missing', {'peaks'})
          .having((s) => s.data.history, 'history', isNotNull),
    ],
  );

  blocTest<AnalyticsCubit, ViewState<AnalyticsOverview>>(
    'el 403 es un error aunque otras partes lleguen',
    setUp: () => when(
      () => accuracy(any()),
    ).thenAnswer((_) async => const Err(ForbiddenFailure())),
    build: build,
    act: (cubit) => cubit.load(_lot),
    skip: 1,
    expect: () => [
      isA<ViewError<AnalyticsOverview>>().having(
        (s) => s.failure,
        'failure',
        isA<ForbiddenFailure>(),
      ),
    ],
  );

  blocTest<AnalyticsCubit, ViewState<AnalyticsOverview>>(
    'si nada llega, es un error recuperable',
    setUp: () {
      when(
        () => history(any()),
      ).thenAnswer((_) async => const Err(NetworkFailure()));
      when(
        () => peaks(any()),
      ).thenAnswer((_) async => const Err(NetworkFailure()));
      when(
        () => accuracy(any()),
      ).thenAnswer((_) async => const Err(NetworkFailure()));
    },
    build: build,
    act: (cubit) => cubit.load(_lot),
    skip: 1,
    expect: () => [
      isA<ViewError<AnalyticsOverview>>().having(
        (s) => s.failure,
        'failure',
        isA<NetworkFailure>(),
      ),
    ],
  );

  blocTest<AnalyticsCubit, ViewState<AnalyticsOverview>>(
    'filtrar por zona solo vuelve a pedir la ocupación (US21 esc. 2)',
    build: build,
    act: (cubit) async {
      await cubit.load(_lot);
      await cubit.selectZone(const ZoneId(10));
    },
    skip: 2,
    expect: () => [
      isA<ViewLoading<AnalyticsOverview>>(),
      isA<ViewData<AnalyticsOverview>>()
          .having((s) => s.data.zoneId, 'zoneId', const ZoneId(10))
          .having(
            (s) => s.data.history!.zoneId,
            'history zone',
            const ZoneId(10),
          ),
    ],
    verify: (_) {
      verify(() => history(any())).called(2);
      verify(() => peaks(any())).called(1);
      verify(() => accuracy(any())).called(1);
    },
  );

  test('otro estacionamiento quita el filtro de zona', () async {
    final cubit = build();
    await cubit.load(_lot);
    await cubit.selectZone(const ZoneId(10));
    await cubit.load(const LotId(2));
    expect(cubit.zoneId, isNull);
    await cubit.close();
  });

  test('un reporte sin contenido no llega al servidor', () async {
    final cubit = build();
    await cubit.load(_lot);
    final result = await cubit.exportReport(
      range: _anyRange,
      sections: const {},
      format: ReportFormat.pdf,
    );
    expect(result.failureOrNull, isA<ValidationFailure>());
    verifyZeroInteractions(export);
    await cubit.close();
  });

  group('riesgo previsto', () {
    test('es el tramo de pronósticos vigentes sobre el umbral', () {
      final now = clock.now();
      final overview = AnalyticsOverview(
        lotId: _lot,
        period: AnalyticsPeriod.today,
        range: _anyRange,
        forecasts: LotForecasts([
          _forecast(ForecastHorizon.min15, 80, now),
          _forecast(ForecastHorizon.min30, 88, now),
          _forecast(ForecastHorizon.min45, 91, now),
          _forecast(ForecastHorizon.min60, 84, now),
        ]),
      );

      final risk = overview.risk(thresholdPct: 85, clock: clock)!;

      expect(risk.from, now.add(const Duration(minutes: 30)));
      expect(risk.to, now.add(const Duration(minutes: 45)));
      expect(risk.peakPct, 91);
      expect(risk.confidence.value, 0.84);
      expect(overview.risk(thresholdPct: 95, clock: clock), isNull);
    });

    test(
      'con una zona filtrada no se usa el pronóstico del estacionamiento',
      () {
        final now = clock.now();
        final overview = AnalyticsOverview(
          lotId: _lot,
          period: AnalyticsPeriod.today,
          range: _anyRange,
          zoneId: const ZoneId(10),
          forecasts: LotForecasts([_forecast(ForecastHorizon.min15, 99, now)]),
        );
        expect(overview.currentForecasts(clock), isEmpty);
        expect(overview.risk(thresholdPct: 85, clock: clock), isNull);
      },
    );
  });
}

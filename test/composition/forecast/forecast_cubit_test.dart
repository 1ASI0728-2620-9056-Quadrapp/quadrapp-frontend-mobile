// US09, US10, US12: Predicción en cada estado.
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quadrapp_mobile/composition/forecast/forecast_cubit.dart';
import 'package:quadrapp_mobile/composition/forecast/forecast_state.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/prediction_advisory.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

import '../../helpers/fake_clock.dart';
import 'support.dart';

class _MockForecasts extends Mock implements GetLotForecasts {}

class _MockRequest extends Mock implements RequestArrivalAdvice {}

void main() {
  late _MockForecasts getForecasts;
  late _MockRequest request;

  setUpAll(() {
    registerFallbackValue(const LotId(1));
    registerFallbackValue(
      const RequestArrivalAdviceParams(lotId: LotId(1), etaMinutes: 1),
    );
  });

  setUp(() {
    getForecasts = _MockForecasts();
    request = _MockRequest();
    when(
      () => getForecasts(any()),
    ).thenAnswer((_) async => Success(forecasts()));
    when(() => request(any())).thenAnswer((invocation) async {
      final params =
          invocation.positionalArguments.single as RequestArrivalAdviceParams;
      return Success(advice(ForecastHorizon.fromMinutes(params.etaMinutes)!));
    });
  });

  ForecastCubit cubit() => ForecastCubit(
    getLotForecasts: getForecasts,
    requestArrivalAdvice: request,
  );

  test('sin sede elegida no hay nada que cargar', () async {
    final c = cubit();
    await c.setLot(null);

    expect(c.state, isA<ViewInitial<ForecastOverview>>());
    verifyNever(() => getForecasts(any()));
    await c.close();
  });

  test(
    'una sede sin distribución publicada no pide nada (US04 esc. 2)',
    () async {
      final c = cubit();
      await c.setLot(lot(layoutVersion: 0));

      expect((c.state as ViewData<ForecastOverview>).data.hasNoData, isTrue);
      verifyNever(() => getForecasts(any()));
      verifyNever(() => request(any()));
      await c.close();
    },
  );

  test('carga los pronósticos y la asesoría de cada horizonte', () async {
    final c = cubit();
    await c.setLot(lot());

    final data = (c.state as ViewData<ForecastOverview>).data;
    expect(data.forecasts?.forecasts, hasLength(4));
    expect(data.advices.map((a) => a.horizon), ForecastHorizon.values);
    // Solo viajan el estacionamiento y los minutos de cada horizonte (TS08).
    final minutes = verify(() => request(captureAny())).captured
        .cast<RequestArrivalAdviceParams>()
        .map((p) => p.etaMinutes)
        .toList();
    expect(minutes, [15, 30, 45, 60]);
    await c.close();
  });

  test(
    'un horizonte sin pronóstico (404) no es un fallo (US10 esc. 2)',
    () async {
      when(() => getForecasts(any())).thenAnswer(
        (_) async => Success(forecasts(missing: {ForecastHorizon.min45})),
      );
      final c = cubit();
      await c.setLot(lot());

      expect(c.state, isA<ViewData<ForecastOverview>>());
      final rows = (c.state as ViewData<ForecastOverview>).data.rows(
        FakeClock(),
      );
      expect(rows[2].status, ForecastRowStatus.missing);
      await c.close();
    },
  );

  test('sin el detalle de los pronósticos: parcial, con la asesoría', () async {
    when(
      () => getForecasts(any()),
    ).thenAnswer((_) async => const Err(NetworkFailure()));
    final c = cubit();
    await c.setLot(lot());

    final state = c.state as ViewPartial<ForecastOverview>;
    expect(state.missing, {'forecasts'});
    expect(state.data.forecasts, isNull);
    expect(state.data.advices.every((a) => a.isAvailable), isTrue);
    await c.close();
  });

  test('si falla todo, error recuperable; al reintentar se recupera', () async {
    when(
      () => getForecasts(any()),
    ).thenAnswer((_) async => const Err(NetworkFailure()));
    when(
      () => request(any()),
    ).thenAnswer((_) async => const Err(NetworkFailure()));
    final c = cubit();
    await c.setLot(lot());

    expect(c.state, isA<ViewError<ForecastOverview>>());
    expect(
      (c.state as ViewError<ForecastOverview>).failure,
      isA<NetworkFailure>(),
    );

    when(
      () => getForecasts(any()),
    ).thenAnswer((_) async => Success(forecasts()));
    when(
      () => request(any()),
    ).thenAnswer((_) async => Success(advice(ForecastHorizon.min15)));
    await c.load();

    expect(c.state, isA<ViewData<ForecastOverview>>());
    await c.close();
  });

  test(
    'sin pronósticos en ningún horizonte, la sede no tiene qué mostrar',
    () async {
      when(
        () => getForecasts(any()),
      ).thenAnswer((_) async => const Success(LotForecasts([])));
      when(
        () => request(any()),
      ).thenAnswer((_) async => const Err(NotFoundFailure()));
      final c = cubit();
      await c.setLot(lot());

      final data = (c.state as ViewData<ForecastOverview>).data;
      expect(data.hasNothing, isTrue);
      await c.close();
    },
  );

  test('al recargar conserva lo que ya se veía', () async {
    final c = cubit();
    await c.setLot(lot());
    final before = (c.state as ViewData<ForecastOverview>).data;

    final states = <ViewState<ForecastOverview>>[];
    final sub = c.stream.listen(states.add);
    await c.refresh();
    await sub.cancel();

    expect((states.first as ViewLoading<ForecastOverview>).previous, before);
    await c.close();
  });

  test('otra sede carga de nuevo; la misma no', () async {
    final c = cubit();
    await c.setLot(lot());
    await c.setLot(lot());
    verify(() => getForecasts(any())).called(1);

    await c.setLot(lot(id: 2));
    verify(() => getForecasts(any())).called(1);
    await c.close();
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/application/usecases/estimate_arrival_eta.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/application/usecases/get_lot_forecasts.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/application/usecases/get_next_availability.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/application/usecases/location_permission_usecases.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/application/usecases/recalculate_arrival_advice.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/application/usecases/request_arrival_advice.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/entities/arrival_advice_request.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/entities/eta_estimate.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/entities/next_availability.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/repositories/arrival_advice_requester.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/repositories/forecast_reader.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/repositories/location_permission_gateway.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/repositories/next_availability_reader.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/services/eta_estimator.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/forecast_horizon.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/geo_point.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

import 'support.dart';

class _MockForecastReader extends Mock implements ForecastReader {}

class _MockAdviceRequester extends Mock implements ArrivalAdviceRequester {}

class _MockNextAvailabilityReader extends Mock
    implements NextAvailabilityReader {}

class _MockEtaEstimator extends Mock implements EtaEstimator {}

class _MockPermissionGateway extends Mock
    implements LocationPermissionGateway {}

class _FakeAdviceRequest extends Fake implements ArrivalAdviceRequest {}

class _FakeEtaContext extends Fake implements EtaEstimationContext {}

void main() {
  setUpAll(() {
    registerFallbackValue(ForecastHorizon.min15);
    registerFallbackValue(_FakeAdviceRequest());
    registerFallbackValue(_FakeEtaContext());
    registerFallbackValue(lotId);
  });

  group('GetLotForecasts (US10)', () {
    late _MockForecastReader reader;

    setUp(() => reader = _MockForecastReader());

    test('pide los 4 horizontes y los devuelve', () async {
      when(() => reader.read(any(), any())).thenAnswer(
        (invocation) async => Success(
          sampleForecast(
            horizon: invocation.positionalArguments[1] as ForecastHorizon,
          ),
        ),
      );

      final result = await GetLotForecasts(reader)(lotId);

      expect(result.valueOrNull?.forecasts, hasLength(4));
      verify(() => reader.read(lotId, any())).called(4);
    });

    test(
      'un horizonte con 404 queda como faltante y el resto se muestra',
      () async {
        when(() => reader.read(any(), any())).thenAnswer((invocation) async {
          final horizon = invocation.positionalArguments[1] as ForecastHorizon;
          return horizon == ForecastHorizon.min45
              ? const Err(NotFoundFailure())
              : Success(sampleForecast(horizon: horizon));
        });

        final result = await GetLotForecasts(reader)(lotId);

        final horizons = result.valueOrNull!.forecasts.map((f) => f.horizon);
        expect(horizons, isNot(contains(ForecastHorizon.min45)));
        expect(horizons, hasLength(3));
      },
    );

    test('todos con 404: pronósticos vacíos, no un error', () async {
      when(
        () => reader.read(any(), any()),
      ).thenAnswer((_) async => const Err(NotFoundFailure()));

      final result = await GetLotForecasts(reader)(lotId);

      expect(result.valueOrNull?.isEmpty, isTrue);
    });

    test('si ninguno llega por una falla real, devuelve esa falla', () async {
      when(
        () => reader.read(any(), any()),
      ).thenAnswer((_) async => const Err(NetworkFailure()));

      final result = await GetLotForecasts(reader)(lotId);

      expect(result.failureOrNull, isA<NetworkFailure>());
    });
  });

  group('RequestArrivalAdvice (US13, TS08)', () {
    late _MockAdviceRequester requester;

    setUp(() => requester = _MockAdviceRequester());

    test('envía lotId y ETA validado y devuelve la asesoría', () async {
      when(
        () => requester.request(any()),
      ).thenAnswer((_) async => Success(sampleAdvice()));

      final result = await RequestArrivalAdvice(requester)(
        const RequestArrivalAdviceParams(lotId: lotId, etaMinutes: 20),
      );

      expect(result.valueOrNull, sampleAdvice());
      final sent =
          verify(() => requester.request(captureAny())).captured.single
              as ArrivalAdviceRequest;
      expect(sent.lotId, lotId);
      expect(sent.etaMinutes.value, 20);
    });

    test('un ETA inválido no llega al servidor', () async {
      for (final minutes in [-1, 121]) {
        final result = await RequestArrivalAdvice(requester)(
          RequestArrivalAdviceParams(lotId: lotId, etaMinutes: minutes),
        );
        expect(result.failureOrNull, isA<ValidationFailure>());
      }
      verifyNever(() => requester.request(any()));
    });
  });

  group('RecalculateArrivalAdvice (US14)', () {
    late _MockAdviceRequester requester;
    late RecalculateArrivalAdvice recalculate;

    setUp(() {
      requester = _MockAdviceRequester();
      recalculate = RecalculateArrivalAdvice(RequestArrivalAdvice(requester));
      when(
        () => requester.request(any()),
      ).thenAnswer((_) async => Success(sampleAdvice(etaMinutes: 35)));
    });

    test('con un ETA distinto consulta de nuevo', () async {
      final result = await recalculate(
        RecalculateArrivalAdviceParams(
          lotId: lotId,
          newEtaMinutes: 35,
          current: sampleAdvice(),
        ),
      );

      expect(result.valueOrNull?.etaMinutes.value, 35);
      verify(() => requester.request(any())).called(1);
    });

    test('un cambio de 1 minuto es ruido: conserva la asesoría', () async {
      final current = sampleAdvice();

      final result = await recalculate(
        RecalculateArrivalAdviceParams(
          lotId: lotId,
          newEtaMinutes: 21,
          current: current,
        ),
      );

      expect(result.valueOrNull, current);
      verifyNever(() => requester.request(any()));
    });

    test('un cambio de 2 minutos consulta de nuevo', () async {
      final result = await recalculate(
        RecalculateArrivalAdviceParams(
          lotId: lotId,
          newEtaMinutes: 22,
          current: sampleAdvice(),
        ),
      );

      expect(result.isSuccess, isTrue);
      verify(() => requester.request(any())).called(1);
    });

    test(
      'con el mismo ETA conserva la asesoría sin llamar al servidor',
      () async {
        final current = sampleAdvice();

        final result = await recalculate(
          RecalculateArrivalAdviceParams(
            lotId: lotId,
            newEtaMinutes: 20,
            current: current,
          ),
        );

        expect(result.valueOrNull, current);
        verifyNever(() => requester.request(any()));
      },
    );

    test(
      'si la asesoría actual no está disponible, vuelve a consultar',
      () async {
        await recalculate(
          RecalculateArrivalAdviceParams(
            lotId: lotId,
            newEtaMinutes: 20,
            current: sampleAdvice(category: null),
          ),
        );

        verify(() => requester.request(any())).called(1);
      },
    );
  });

  group('GetNextAvailability (US36)', () {
    late _MockNextAvailabilityReader reader;

    setUp(() => reader = _MockNextAvailabilityReader());

    test(
      'con espacios libres no es aplicable y no llama al servidor',
      () async {
        final result = await GetNextAvailability(reader)(
          const GetNextAvailabilityParams(lotId: lotId, hasFreeSpaces: true),
        );

        expect(result.valueOrNull, const NextAvailabilityNotApplicable());
        verifyNever(() => reader.read(any()));
      },
    );

    test('sin espacios libres consulta la próxima liberación', () async {
      const estimate = NextAvailabilityEstimate(minMinutes: 8, maxMinutes: 15);
      when(
        () => reader.read(any()),
      ).thenAnswer((_) async => const Success(estimate));

      final result = await GetNextAvailability(reader)(
        const GetNextAvailabilityParams(lotId: lotId, hasFreeSpaces: false),
      );

      expect(result.valueOrNull, estimate);
    });
  });

  group('EstimateArrivalEta (US13)', () {
    late _MockEtaEstimator manual;
    late _MockEtaEstimator automatic;
    late EstimateArrivalEta estimate;

    setUp(() {
      manual = _MockEtaEstimator();
      automatic = _MockEtaEstimator();
      estimate = EstimateArrivalEta(manual: manual, automatic: automatic);
      when(() => manual.estimate(any())).thenAnswer(
        (_) async =>
            Success(EtaEstimate(minutes: eta(18), source: EtaSource.manual)),
      );
      when(() => automatic.estimate(any())).thenAnswer(
        (_) async => Success(
          EtaEstimate(minutes: eta(10), source: EtaSource.device),
        ),
      );
    });

    test('un ETA manual tiene prioridad y no se consulta el GPS', () async {
      final result = await estimate(
        const EstimateArrivalEtaParams(
          destination: GeoPoint(latitude: -12, longitude: -77),
          manualMinutes: 18,
        ),
      );

      expect(result.valueOrNull?.source, EtaSource.manual);
      verifyNever(() => automatic.estimate(any()));
    });

    test('sin ETA manual usa el estimador automático', () async {
      final result = await estimate(
        const EstimateArrivalEtaParams(
          destination: GeoPoint(latitude: -12, longitude: -77),
        ),
      );

      expect(result.valueOrNull?.source, EtaSource.device);
      verifyNever(() => manual.estimate(any()));
    });
  });

  group('permiso de ubicación', () {
    late _MockPermissionGateway gateway;

    setUp(() => gateway = _MockPermissionGateway());

    test('consultar el estado no pide el permiso', () async {
      when(
        () => gateway.status(),
      ).thenAnswer((_) async => LocationPermissionStatus.denied);

      final result = await GetLocationPermissionStatus(gateway)(
        const NoParams(),
      );

      expect(result.valueOrNull, LocationPermissionStatus.denied);
      verifyNever(() => gateway.request());
    });

    test('pedir el permiso devuelve el resultado; un fallo no lanza', () async {
      when(
        () => gateway.request(),
      ).thenAnswer((_) async => LocationPermissionStatus.granted);
      expect(
        (await RequestLocationPermission(gateway)(
          const NoParams(),
        )).valueOrNull,
        LocationPermissionStatus.granted,
      );

      when(() => gateway.request()).thenThrow(StateError('plataforma'));
      expect(
        (await RequestLocationPermission(gateway)(const NoParams())).isFailure,
        isTrue,
      );
    });
  });
}

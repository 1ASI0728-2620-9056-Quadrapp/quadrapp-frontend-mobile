import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/application/usecases/estimate_arrival_eta.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/application/usecases/request_arrival_advice.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/entities/forecast.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/entities/next_availability.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/repositories/location_permission_gateway.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/repositories/position_source.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/services/device_route_eta_estimator.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/services/manual_eta_estimator.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/arrival_category.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/confidence.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/forecast_horizon.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/geo_point.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/infrastructure/datasources/prediction_http_datasources.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/infrastructure/dto/prediction_dtos.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/infrastructure/eta/geolocator_location_gateway.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/infrastructure/eta/local_route_provider.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/infrastructure/mappers/prediction_mapper.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/infrastructure/repositories/prediction_repositories.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/fake_http_adapter.dart';
import '../../helpers/recording_logger.dart';
import 'support.dart';

class _FixedPosition implements PositionSource {
  const _FixedPosition(this.point);

  final GeoPoint point;

  @override
  Future<GeoPoint?> currentPosition() async => point;
}

void main() {
  late RecordingLogger logger;
  late PredictionMapper mapper;

  setUp(() {
    logger = RecordingLogger();
    mapper = PredictionMapper(logger);
  });

  group('PredictionMapper', () {
    test('caso feliz: pronóstico con saturación y vigencia', () {
      final forecast = mapper.toForecast(
        ForecastDto.fromJson(forecastJson()),
        ForecastHorizon.min30,
        receivedAt: Duration.zero,
      );

      expect(forecast.expectedOccupancyPct, 86);
      expect(forecast.confidence.level, ConfidenceLevel.high);
      expect(forecast.method, ForecastMethod.primaryModel);
      expect(forecast.saturation?.pct, 93.5);
      expect(forecast.validity.remaining(FakeClock()).inMinutes, 13);
      expect(logger.messages, isEmpty);
    });

    test('valores desconocidos: confianza LOW, método FALLBACK', () {
      final forecast = mapper.toForecast(
        ForecastDto.fromJson(
          forecastJson(method: 'QUANTUM', level: 'EXTREME', saturation: null),
        ),
        ForecastHorizon.min30,
        receivedAt: Duration.zero,
      );

      expect(forecast.confidence.level, ConfidenceLevel.low);
      expect(forecast.method, ForecastMethod.fallback);
      expect(forecast.saturation, isNull);
      expect(logger.messages, hasLength(2));
    });

    test('categoría desconocida: sin categoría, asesoría no disponible', () {
      final advice = mapper.toAdvice(
        ArrivalAdviceDto.fromJson(adviceJson(category: 'MAYBE')),
      );

      expect(advice.category, isNull);
      expect(advice.isAvailable, isFalse);
      expect(
        mapper
            .toAdvice(
              ArrivalAdviceDto.fromJson(adviceJson(category: 'LIMITED')),
            )
            .category,
        ArrivalCategory.limited,
      );
    });

    test('la antigüedad de la asesoría usa la hora del servidor y el tiempo '
        'local, no el reloj del teléfono', () {
      final clock = FakeClock();
      final advice = mapper.toAdvice(
        ArrivalAdviceDto.fromJson(adviceJson()),
        receivedAt: clock.monotonic(),
      );

      // generatedAt 13:40 y serverTime 13:42: dos minutos.
      expect(advice.age(clock), const Duration(minutes: 2));
      // Un reloj de pared desfasado no cambia nada.
      clock.wallClock = DateTime.utc(2030);
      expect(advice.age(clock), const Duration(minutes: 2));
      // El tiempo transcurrido localmente sí suma.
      clock.advance(const Duration(seconds: 30));
      expect(advice.age(clock), const Duration(minutes: 2, seconds: 30));
    });

    test('sin hora del servidor ni lectura local la antigüedad es cero', () {
      final advice = mapper.toAdvice(
        ArrivalAdviceDto.fromJson(adviceJson()),
      );

      expect(advice.age(FakeClock()), Duration.zero);
    });

    test(
      'próxima liberación: rango, sin salidas, hay libres y desconocido',
      () {
        NextAvailability map(Map<String, Object?> json) =>
            mapper.toNextAvailability(NextAvailabilityDto.fromJson(json));

        expect(
          map(nextAvailabilityJson()),
          isA<NextAvailabilityEstimate>()
              .having((e) => e.minMinutes, 'min', 8)
              .having((e) => e.maxMinutes, 'max', 15),
        );
        expect(
          map(nextAvailabilityJson(available: false, reason: 'NO_EXITS')),
          isA<NextAvailabilityNoEstimate>(),
        );
        expect(
          map(
            nextAvailabilityJson(available: false, reason: 'HAS_FREE_SPACES'),
          ),
          isA<NextAvailabilityNotApplicable>(),
        );
        expect(
          map(nextAvailabilityJson(available: false, reason: 'OTHER')),
          isA<NextAvailabilityNoEstimate>(),
        );
      },
    );
  });

  group('repositorios', () {
    test('error de red al pedir un pronóstico es NetworkFailure', () async {
      final adapter = FakeHttpAdapter(
        (options) => throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      );
      final reader = ForecastReaderImpl(
        remote: ForecastHttpDataSource(dioWith(adapter)),
        mapper: mapper,
        clock: FakeClock(),
      );

      final result = await reader.read(lotId, ForecastHorizon.min15);

      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    // `ForecastResource` del backend, campo por campo.
    Map<String, Object?> backendForecast(
      int horizon, {
      Object? saturationExpectedAt,
    }) => {
      'id': 100 + horizon,
      'parkingLotId': 1,
      'horizonMinutes': horizon,
      'generatedAt': '2026-11-14T15:00:04Z',
      'targetAt': '2026-11-14T15:15:00Z',
      'expectedOccupancyPct': 72.5,
      'confidence': 0.81,
      'confidenceLevel': 'HIGH',
      'method': 'PRIMARY_MODEL',
      'modelVersion': 'v3',
      'saturationExpectedAt': saturationExpectedAt,
      'observedOccupancyPct': null,
      'absoluteError': null,
      'runId': '6f1c2a8e-0f4e-4a43-9c55-1b2a3c4d5e6f',
      'runSlot': '2026-11-14T15:00:00Z',
      'trigger': 'SCHEDULED',
    };

    test('lee el horizonte pedido de la última corrida '
        '(GET /parking-lots/{id}/forecasts)', () async {
      final adapter = FakeHttpAdapter(
        (options) => options.path == '/parking-lots/1'
            ? jsonResponse({'id': 1, 'saturationThresholdPct': 85})
            : jsonResponse(
                [
                  backendForecast(15),
                  backendForecast(
                    30,
                    saturationExpectedAt: '2026-11-14T15:25:00Z',
                  ),
                ],
                headers: {
                  'date': ['Fri, 14 Nov 2026 15:01:00 GMT'],
                },
              ),
      );

      final dto = await ForecastHttpDataSource(
        dioWith(adapter),
      ).fetch(lotId, 30);

      expect(adapter.requests.first.path, '/parking-lots/1/forecasts');
      expect(dto.horizon, 30);
      expect(dto.expectedOccupancyPct, 72.5);
      expect(dto.confidence.value, 0.81);
      expect(dto.confidence.level, 'HIGH');
      expect(dto.method, 'PRIMARY_MODEL');
      expect(dto.modelVersion, 'v3');
      expect(dto.generatedAt, DateTime.utc(2026, 11, 14, 15, 0, 4));
      expect(dto.validUntil, DateTime.utc(2026, 11, 14, 15, 10));
      expect(dto.serverTime, DateTime.utc(2026, 11, 14, 15, 1));
      expect(dto.saturation?.expectedAt, DateTime.utc(2026, 11, 14, 15, 25));
      expect(dto.saturation?.pct, 85);
      final forecast = mapper.toForecast(
        dto,
        ForecastHorizon.min30,
        receivedAt: Duration.zero,
      );
      expect(forecast.method, ForecastMethod.primaryModel);
      expect(forecast.confidence.level, ConfidenceLevel.high);
    });

    test(
      'un horizonte que no está en la corrida es NotFoundFailure',
      () async {
        final adapter = FakeHttpAdapter(
          (_) => jsonResponse([backendForecast(15)]),
        );
        final reader = ForecastReaderImpl(
          remote: ForecastHttpDataSource(dioWith(adapter)),
          mapper: mapper,
          clock: FakeClock(),
        );

        final result = await reader.read(lotId, ForecastHorizon.min45);

        expect(result.failureOrNull, isA<NotFoundFailure>());
      },
    );

    test('una respuesta que no es un arreglo es ParseFailure', () async {
      final adapter = FakeHttpAdapter((_) => jsonResponse({'a': 1}));
      final reader = ForecastReaderImpl(
        remote: ForecastHttpDataSource(dioWith(adapter)),
        mapper: mapper,
        clock: FakeClock(),
      );

      final result = await reader.read(lotId, ForecastHorizon.min15);

      expect(result.failureOrNull, isA<ParseFailure>());
    });

    test(
      'la asesoría de llegada lee el ArrivalAdviceResource del backend',
      () async {
        final adapter = FakeHttpAdapter(
          (_) => jsonResponse({
            'etaMinutes': 20,
            'probabilityOfSpace': 0.62,
            'category': 'LIMITED',
            'confidence': {'value': 0.55, 'level': 'MEDIUM'},
            'horizonUsed': 30,
            'generatedAt': '2026-11-14T15:00:04Z',
            'serverTime': '2026-11-14T15:01:00Z',
          }),
        );
        final requester = ArrivalAdviceRequesterImpl(
          remote: ArrivalAdviceHttpDataSource(dioWith(adapter)),
          mapper: mapper,
          clock: FakeClock(),
        );

        final advice = (await RequestArrivalAdvice(requester)(
          const RequestArrivalAdviceParams(lotId: lotId, etaMinutes: 20),
        )).valueOrNull!;

        expect(adapter.requests.single.path, '/arrival-advices');
        expect(advice.category, ArrivalCategory.limited);
        expect(advice.probabilityOfSpace, 0.62);
        expect(advice.horizonUsed, ForecastHorizon.min30);
        expect(advice.confidence.level, ConfidenceLevel.medium);
      },
    );

    test('sin ruta en el backend, la próxima liberación es "sin estimación" '
        'y no llama a la red', () async {
      final dto = await const UnavailableNextAvailabilityDataSource().fetch(
        lotId,
      );

      expect(mapper.toNextAvailability(dto), isA<NextAvailabilityNoEstimate>());
    });
  });

  group('privacidad del ETA (TS08 esc. 3)', () {
    test('el DTO del request serializa SOLO lotId y etaMinutes', () {
      final json = const ArrivalAdviceRequestDto(
        lotId: 1,
        etaMinutes: 20,
      ).toJson();

      // Si alguien agrega un campo (p. ej. coordenadas), esto falla.
      expect(json.keys.toSet(), {'lotId', 'etaMinutes'});
      expect(json, {'lotId': 1, 'etaMinutes': 20});
    });

    test(
      'con GPS, lo que viaja al servidor son solo lotId y minutos',
      () async {
        const position = GeoPoint(latitude: -12.098765, longitude: -76.987654);
        const destination = GeoPoint(latitude: -12.1035, longitude: -76.963);
        final adapter = FakeHttpAdapter((_) => jsonResponse(adviceJson()));
        final requester = ArrivalAdviceRequesterImpl(
          remote: ArrivalAdviceHttpDataSource(dioWith(adapter)),
          mapper: mapper,
          clock: FakeClock(),
        );
        const estimate = EstimateArrivalEta(
          manual: ManualEtaEstimator(),
          automatic: DeviceRouteEtaEstimator(
            positionSource: _FixedPosition(position),
            routeProvider: LocalRouteProvider(),
          ),
        );

        final estimated = await estimate(
          const EstimateArrivalEtaParams(destination: destination),
        );
        final minutes = estimated.valueOrNull!.minutes.value;
        await RequestArrivalAdvice(requester)(
          RequestArrivalAdviceParams(lotId: lotId, etaMinutes: minutes),
        );

        final request = adapter.requests.single;
        expect(request.method, 'POST');
        expect((request.data as Map).keys.toSet(), {'lotId', 'etaMinutes'});
        expect(request.data, {'lotId': 1, 'etaMinutes': minutes});
        // Ninguna parte de la petición menciona la posición del usuario.
        final everything = jsonEncode({
          'uri': request.uri.toString(),
          'headers': request.headers,
          'query': request.queryParameters,
          'body': request.data,
        });
        for (final fragment in [
          '12.098765',
          '76.987654',
          'latitude',
          'longitude',
        ]) {
          expect(everything, isNot(contains(fragment)));
        }
      },
    );
  });

  group('permiso de ubicación (geolocator)', () {
    test('mapea el permiso de la plataforma al del dominio', () {
      LocationPermissionStatus map(
        LocationPermission permission, {
        bool service = true,
      }) => mapLocationPermission(permission, serviceEnabled: service);

      expect(
        map(LocationPermission.whileInUse),
        LocationPermissionStatus.granted,
      );
      expect(map(LocationPermission.always), LocationPermissionStatus.granted);
      expect(map(LocationPermission.denied), LocationPermissionStatus.denied);
      expect(
        map(LocationPermission.deniedForever),
        LocationPermissionStatus.deniedForever,
      );
      expect(
        map(LocationPermission.whileInUse, service: false),
        LocationPermissionStatus.serviceDisabled,
      );
    });
  });
}

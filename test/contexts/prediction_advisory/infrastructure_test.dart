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

    test(
      '404 de un horizonte es NotFoundFailure y pide lotId y horizon',
      () async {
        final adapter = FakeHttpAdapter(
          (options) =>
              jsonResponse({'status': 404, 'title': 'Not Found'}, status: 404),
        );
        final reader = ForecastReaderImpl(
          remote: ForecastHttpDataSource(dioWith(adapter)),
          mapper: mapper,
          clock: FakeClock(),
        );

        final result = await reader.read(lotId, ForecastHorizon.min45);

        expect(result.failureOrNull, isA<NotFoundFailure>());
        expect(adapter.requests.single.queryParameters, {
          'lotId': 1,
          'horizon': 45,
        });
      },
    );

    test('una respuesta que no es un objeto JSON es ParseFailure', () async {
      final adapter = FakeHttpAdapter((_) => jsonResponse([1, 2]));
      final reader = ForecastReaderImpl(
        remote: ForecastHttpDataSource(dioWith(adapter)),
        mapper: mapper,
        clock: FakeClock(),
      );

      final result = await reader.read(lotId, ForecastHorizon.min15);

      expect(result.failureOrNull, isA<ParseFailure>());
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

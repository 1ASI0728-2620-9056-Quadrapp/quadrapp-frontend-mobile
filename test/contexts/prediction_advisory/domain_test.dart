import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/entities/eta_estimate.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/entities/forecast.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/entities/lot_forecasts.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/repositories/position_source.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/repositories/route_provider.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/services/device_route_eta_estimator.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/services/eta_estimator.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/services/manual_eta_estimator.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/confidence.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/eta_minutes.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/forecast_horizon.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/geo_point.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/infrastructure/eta/local_route_provider.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

import '../../helpers/fake_clock.dart';
import 'support.dart';

class _Position implements PositionSource {
  _Position(this.handler);

  Future<GeoPoint?> Function() handler;

  @override
  Future<GeoPoint?> currentPosition() => handler();
}

class _Route implements RouteProvider {
  _Route(this.handler, {this.basis = RouteBasis.distance});

  Future<Duration?> Function() handler;
  final RouteBasis basis;
  final List<GeoPoint> origins = [];

  @override
  Future<RouteTravel?> travelTime({
    required GeoPoint from,
    required GeoPoint to,
  }) async {
    origins.add(from);
    final duration = await handler();
    return duration == null
        ? null
        : RouteTravel(duration: duration, basis: basis);
  }
}

const _origin = GeoPoint(latitude: -12.09, longitude: -76.98);
const _destination = GeoPoint(latitude: -12.1035, longitude: -76.963);

DeviceRouteEtaEstimator _device({
  Future<GeoPoint?> Function()? position,
  Future<Duration?> Function()? route,
  _Route? traffic,
}) => DeviceRouteEtaEstimator(
  positionSource: _Position(position ?? () async => _origin),
  routeProvider: _Route(route ?? () async => const Duration(minutes: 12)),
  trafficProvider: traffic,
);

void main() {
  group('EtaMinutes (0..120)', () {
    test('acepta los límites 0 y 120', () {
      expect(EtaMinutes.create(0).valueOrNull?.value, 0);
      expect(EtaMinutes.create(120).valueOrNull?.value, 120);
    });

    test('rechaza negativos y más de 120 con ValidationFailure', () {
      expect(EtaMinutes.create(-1).failureOrNull, isA<ValidationFailure>());
      expect(EtaMinutes.create(121).failureOrNull, isA<ValidationFailure>());
    });

    test('un cambio de al menos 2 minutos cuenta como cambio (ruido: no)', () {
      expect(eta(20).changedEnoughFrom(eta(20)), isFalse);
      expect(eta(21).changedEnoughFrom(eta(20)), isFalse);
      expect(eta(22).changedEnoughFrom(eta(20)), isTrue);
      expect(eta(18).changedEnoughFrom(eta(20)), isTrue);
    });
  });

  group('ForecastHorizon.nearestTo', () {
    test('elige el más cercano; empate: el mayor; más de 60: 60', () {
      expect(ForecastHorizon.nearestTo(0), ForecastHorizon.min15);
      expect(ForecastHorizon.nearestTo(22), ForecastHorizon.min15);
      expect(ForecastHorizon.nearestTo(23), ForecastHorizon.min30);
      expect(ForecastHorizon.nearestTo(30), ForecastHorizon.min30);
      expect(ForecastHorizon.nearestTo(52), ForecastHorizon.min45);
      expect(ForecastHorizon.nearestTo(120), ForecastHorizon.min60);
    });

    test('fromMinutes devuelve null si no es un horizonte admitido', () {
      expect(ForecastHorizon.fromMinutes(45), ForecastHorizon.min45);
      expect(ForecastHorizon.fromMinutes(20), isNull);
    });
  });

  group('LotForecasts.slots (US10)', () {
    test('un horizonte ausente figura como faltante y es parcial', () {
      final clock = FakeClock();
      final forecasts = LotForecasts([
        sampleForecast(horizon: ForecastHorizon.min15),
        sampleForecast(horizon: ForecastHorizon.min45),
      ]);

      final slots = forecasts.slots(clock);

      expect(slots.map((s) => s.horizon), ForecastHorizon.values);
      expect(slots.map((s) => s.status), [
        ForecastSlotStatus.available,
        ForecastSlotStatus.missing,
        ForecastSlotStatus.available,
        ForecastSlotStatus.missing,
      ]);
      expect(forecasts.isPartial(clock), isTrue);
    });

    test('un pronóstico vencido (tiempo local) no se muestra como actual', () {
      final clock = FakeClock();
      final forecasts = LotForecasts([sampleForecast()]);

      expect(forecasts.slots(clock)[1].status, ForecastSlotStatus.available);
      clock.advance(const Duration(minutes: 14));

      final slot = forecasts.slots(clock)[1];
      expect(slot.status, ForecastSlotStatus.expired);
      expect(slot.current, isNull);
    });

    test('la vigencia no depende de la hora de pared del teléfono', () {
      final clock = FakeClock();
      final forecast = sampleForecast();

      clock.wallClock = DateTime.utc(2030);

      expect(forecast.validity.isExpired(clock), isFalse);
      expect(forecast.validity.remaining(clock), const Duration(minutes: 13));
    });
  });

  group('Forecast y ArrivalAdvice', () {
    test('FALLBACK o confianza baja se marcan como poco fiables', () {
      expect(sampleForecast().isLowConfidence, isFalse);
      expect(
        sampleForecast(method: ForecastMethod.fallback).isLowConfidence,
        isTrue,
      );
      expect(
        sampleForecast(level: ConfidenceLevel.low).isLowConfidence,
        isTrue,
      );
    });

    test('una asesoría sin categoría no está disponible', () {
      expect(sampleAdvice().isAvailable, isTrue);
      expect(sampleAdvice(category: null).isAvailable, isFalse);
    });
  });

  group('GeoPoint', () {
    test('la distancia entre dos puntos cercanos es razonable', () {
      final km = _origin.distanceKmTo(_destination);
      expect(km, inInclusiveRange(2, 3));
      expect(_origin.distanceKmTo(_origin), 0);
    });
  });

  group('ManualEtaEstimator', () {
    test('devuelve el ETA manual con origen manual', () async {
      final result = await const ManualEtaEstimator().estimate(
        const EtaEstimationContext(manualMinutes: 18),
      );

      expect(result.valueOrNull?.minutes.value, 18);
      expect(result.valueOrNull?.source, EtaSource.manual);
    });

    test('sin minutos no hay estimación; fuera de rango es Err', () async {
      const estimator = ManualEtaEstimator();
      expect(
        (await estimator.estimate(const EtaEstimationContext())).valueOrNull,
        isNull,
      );
      expect(
        (await estimator.estimate(
          const EtaEstimationContext(manualMinutes: 200),
        )).failureOrNull,
        isA<ValidationFailure>(),
      );
    });
  });

  group('DeviceRouteEtaEstimator (US13)', () {
    const context = EtaEstimationContext(destination: _destination);

    test('estima, marca "estimado" y redondea a bloques de 5', () async {
      for (final (travel, expected) in [
        (const Duration(minutes: 12), 10),
        (const Duration(minutes: 13), 15),
        (const Duration(minutes: 1), 0),
        (const Duration(minutes: 37), 35),
      ]) {
        final result = await _device(
          route: () async => travel,
        ).estimate(context);
        expect(result.valueOrNull?.minutes.value, expected);
        expect(result.valueOrNull?.source, EtaSource.device);
      }
    });

    group('con tráfico', () {
      const withTraffic = EtaEstimationContext(
        destination: _destination,
        useTraffic: true,
      );

      test('usa el proveedor de mapas y redondea al minuto', () async {
        final traffic = _Route(
          () async => const Duration(minutes: 13, seconds: 40),
          basis: RouteBasis.traffic,
        );

        final result = await _device(traffic: traffic).estimate(withTraffic);

        expect(result.valueOrNull?.minutes.value, 14);
        expect(result.valueOrNull?.source, EtaSource.traffic);
      });

      test(
        'al proveedor solo viaja el origen redondeado a unos 100 m',
        () async {
          final traffic = _Route(
            () async => const Duration(minutes: 13),
            basis: RouteBasis.traffic,
          );

          await _device(
            position: () async =>
                const GeoPoint(latitude: -12.123456, longitude: -77.029789),
            traffic: traffic,
          ).estimate(withTraffic);

          expect(
            traffic.origins.single,
            const GeoPoint(latitude: -12.123, longitude: -77.03),
          );
        },
      );

      test('sin activarlo, no consulta al proveedor: usa lo local', () async {
        final traffic = _Route(
          () async => const Duration(minutes: 30),
          basis: RouteBasis.traffic,
        );

        final result = await _device(traffic: traffic).estimate(context);

        expect(traffic.origins, isEmpty);
        expect(result.valueOrNull?.source, EtaSource.device);
        expect(result.valueOrNull?.minutes.value, 10);
      });

      test('sin proveedor (sin clave), baja a lo local sin error', () async {
        final result = await _device().estimate(withTraffic);

        expect(result.valueOrNull?.source, EtaSource.device);
      });

      test('si el proveedor no responde o falla, baja a lo local', () async {
        final silent = await _device(
          traffic: _Route(() async => null, basis: RouteBasis.traffic),
        ).estimate(withTraffic);
        final broken = await _device(
          traffic: _Route(
            () async => throw StateError('cuota'),
            basis: RouteBasis.traffic,
          ),
        ).estimate(withTraffic);

        for (final result in [silent, broken]) {
          expect(result.valueOrNull?.source, EtaSource.device);
          expect(result.valueOrNull?.minutes.value, 10);
        }
      });

      test('sin posición no hay ETA aunque haya proveedor (manual)', () async {
        final traffic = _Route(
          () async => const Duration(minutes: 5),
          basis: RouteBasis.traffic,
        );

        final result = await _device(
          position: () async => null,
          traffic: traffic,
        ).estimate(withTraffic);

        expect(result, const Success<EtaEstimate?>(null));
        expect(traffic.origins, isEmpty);
      });

      test(
        'más de 120 minutos con tráfico también es un error de validación',
        () async {
          final result = await _device(
            traffic: _Route(
              () async => const Duration(hours: 3),
              basis: RouteBasis.traffic,
            ),
          ).estimate(withTraffic);

          expect(result.failureOrNull, isA<ValidationFailure>());
        },
      );
    });

    test('lote sin coordenadas: no consulta posición ni ruta', () async {
      var asked = false;
      final result = await _device(
        position: () async {
          asked = true;
          return _origin;
        },
      ).estimate(const EtaEstimationContext());

      expect(result, const Success<EtaEstimate?>(null));
      expect(asked, isFalse);
    });

    test('sin posición (permiso negado, GPS apagado) usa el manual', () async {
      final result = await _device(
        position: () async => null,
      ).estimate(context);
      expect(result, const Success<EtaEstimate?>(null));
    });

    test('una excepción de la plataforma no cruza la capa', () async {
      final byPosition = await _device(
        position: () async => throw StateError('gps'),
      ).estimate(context);
      final byRoute = await _device(
        route: () async => throw StateError('ruta'),
      ).estimate(context);
      final noRoute = await _device(route: () async => null).estimate(context);

      expect(byPosition, const Success<EtaEstimate?>(null));
      expect(byRoute, const Success<EtaEstimate?>(null));
      expect(noRoute, const Success<EtaEstimate?>(null));
    });

    test('más de 120 minutos es un error de validación, no un ETA', () async {
      final result = await _device(
        route: () async => const Duration(hours: 3),
      ).estimate(context);

      expect(result.failureOrNull, isA<ValidationFailure>());
    });
  });

  group('LocalRouteProvider', () {
    test('distancia × factor de desvío ÷ velocidad media, sin red', () async {
      const from = GeoPoint(latitude: -12, longitude: -77);
      const to = GeoPoint(latitude: -12.1, longitude: -77);

      final travel = await const LocalRouteProvider().travelTime(
        from: from,
        to: to,
      );

      // ~11,1 km en línea recta × 1,35 ÷ 25 km/h ≈ 36 minutos.
      expect(travel?.duration.inMinutes, inInclusiveRange(35, 37));
      expect(travel?.basis, RouteBasis.distance);
    });
  });
}

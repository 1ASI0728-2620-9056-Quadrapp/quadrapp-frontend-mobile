// Los mocks de la asesoría (una curva con buena, limitada y baja disponibilidad
// entre sedes y horizontes) y la ubicación simulada del teléfono.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/app/mocks/mock_controls.dart';
import 'package:quadrapp_mobile/app/mocks/mock_world.dart';
import 'package:quadrapp_mobile/app/mocks/prediction_advisory/mock_location.dart';
import 'package:quadrapp_mobile/app/mocks/prediction_advisory/mock_prediction_json.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/repositories/location_permission_gateway.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/services/device_route_eta_estimator.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/services/eta_estimator.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/geo_point.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/infrastructure/eta/local_route_provider.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/test_seed.dart';

MockWorld newWorld({MockControls? controls}) => MockWorld(
  seed: testSeed,
  clock: FakeClock(),
  controls: controls,
  random: Random(1),
  latency: false,
);

void main() {
  group('la asesoría de los mocks', () {
    ({double probability, String category}) at(
      MockWorld world,
      int lotId,
      int horizon,
    ) {
      final json = mockAdviceJson(world, world.lot(lotId)!, horizon);
      return (
        probability: json['probabilityOfSpace']! as double,
        category: json['category']! as String,
      );
    }

    test('Monterrico baja de buena a baja disponibilidad con el horizonte', () {
      final world = newWorld();

      expect(
        [
          for (final h in [15, 30, 45, 60]) at(world, 1, h).category,
        ],
        ['HIGH', 'HIGH', 'LIMITED', 'LOW'],
      );
      final probabilities = <double>[
        for (final h in [15, 30, 45, 60]) at(world, 1, h).probability,
      ];
      final sortedDescending = [...probabilities]
        ..sort((a, b) => b.compareTo(a));
      expect(probabilities, orderedEquals(sortedDescending));
    });

    test('San Isidro, lleno, es de baja disponibilidad en todos', () {
      final world = newWorld();

      for (final h in [15, 30, 45, 60]) {
        expect(at(world, 2, h).category, 'LOW', reason: '$h min');
        expect(at(world, 2, h).probability, 0);
      }
    });

    test('Villa, con muchos libres, es de buena disponibilidad en todos', () {
      final world = newWorld();

      for (final h in [15, 30, 45, 60]) {
        expect(at(world, 4, h).category, 'HIGH', reason: '$h min');
      }
    });

    test('San Miguel, sin distribución, da una estimación de respaldo de '
        'confianza baja', () {
      final world = newWorld();
      final json = mockAdviceJson(world, world.lot(3)!, 30);

      expect(json['category'], 'LIMITED');
      expect((json['confidence']! as Map<String, Object?>)['level'], 'LOW');
    });

    test('el pronóstico de Monterrico no prevé saturación en una hora', () {
      final world = newWorld();

      for (final h in [15, 30, 45, 60]) {
        final json = mockForecastJson(world, world.lot(1)!, h);
        expect(json.containsKey('saturation'), isFalse, reason: '$h min');
      }
    });
  });

  group('MockLocationGateway', () {
    late MockControls controls;
    late MockLocationGateway gateway;

    setUp(() {
      controls = MockControls();
      gateway = MockLocationGateway(controls);
    });

    test(
      'concedido: da la posición fija y el ETA de cada sede es distinto',
      () async {
        expect(await gateway.status(), LocationPermissionStatus.granted);
        final position = await gateway.currentPosition();
        expect(position, MockLocationGateway.position);

        final world = newWorld();
        final estimator = DeviceRouteEtaEstimator(
          positionSource: gateway,
          routeProvider: const LocalRouteProvider(),
        );
        Future<int?> etaTo(int lotId) async {
          final lot = world.lot(lotId)!;
          final result = await estimator.estimate(
            EtaEstimationContext(
              destination: GeoPoint(
                latitude: lot.latitude!,
                longitude: lot.longitude!,
              ),
            ),
          );
          return result.valueOrNull?.minutes.value;
        }

        final etas = [await etaTo(1), await etaTo(2), await etaTo(4)];
        expect(etas.every((e) => e != null && e % 5 == 0), isTrue);
        expect(etas.toSet().length, greaterThan(1));
      },
    );

    test('sin permiso no hay posición', () async {
      controls.locationPermission = LocationPermissionStatus.denied;

      expect(await gateway.currentPosition(), isNull);
    });

    test(
      'pedir el permiso lo concede, salvo que el diálogo lo niegue',
      () async {
        controls.locationPermission = LocationPermissionStatus.denied;
        expect(await gateway.request(), LocationPermissionStatus.granted);
        expect(controls.locationPermission, LocationPermissionStatus.granted);

        controls
          ..locationPermission = LocationPermissionStatus.denied
          ..denyLocationPrompt = true;
        // La primera negativa deja «denegado»; la segunda, «para siempre».
        expect(await gateway.request(), LocationPermissionStatus.denied);
        expect(await gateway.request(), LocationPermissionStatus.deniedForever);
        expect(await gateway.request(), LocationPermissionStatus.deniedForever);
      },
    );

    test('con la ubicación apagada no se puede pedir', () async {
      controls.locationPermission = LocationPermissionStatus.serviceDisabled;

      expect(await gateway.request(), LocationPermissionStatus.serviceDisabled);
      expect(await gateway.currentPosition(), isNull);
    });
  });
}

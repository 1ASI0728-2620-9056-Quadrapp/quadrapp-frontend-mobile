// US13, US14: el viaje simulado del teléfono y el proveedor de mapas simulado,
// para ver bajar el ETA y actualizarse la asesoría sin salir a manejar.
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/app/mocks/mock_controls.dart';
import 'package:quadrapp_mobile/app/mocks/mock_world.dart';
import 'package:quadrapp_mobile/app/mocks/prediction_advisory/mock_location.dart';
import 'package:quadrapp_mobile/app/mocks/prediction_advisory/mock_traffic_route_provider.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/repositories/selected_lot_store.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/entities/eta_estimate.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/repositories/location_permission_gateway.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/services/device_route_eta_estimator.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/services/eta_estimator.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/geo_point.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/infrastructure/eta/local_route_provider.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/test_seed.dart';

class _Store implements SelectedLotStore {
  _Store(this.id);

  LotId? id;

  @override
  Future<LotId?> read() async => id;

  @override
  Future<void> save(LotId lotId) async => id = lotId;

  @override
  Future<void> clear() async => id = null;
}

void main() {
  late MockControls controls;
  late FakeClock clock;
  late MockWorld world;
  late _Store store;
  late MockLocationGateway gateway;
  late GeoPoint campus;

  setUp(() {
    controls = MockControls();
    clock = FakeClock();
    world = MockWorld(
      seed: testSeed,
      clock: clock,
      controls: controls,
      random: Random(1),
      latency: false,
    );
    store = _Store(const LotId(1));
    gateway = MockLocationGateway(
      controls,
      clock: clock,
      world: world,
      selectedLot: store,
    );
    final lot = world.lot(1)!;
    campus = GeoPoint(latitude: lot.latitude!, longitude: lot.longitude!);
  });

  Future<double> kmToCampus() async =>
      (await gateway.currentPosition())!.distanceKmTo(campus);

  group('el teléfono simulado', () {
    test('sin viaje queda en Miraflores aunque pase el tiempo', () async {
      clock.advance(const Duration(minutes: 30));

      expect(await gateway.currentPosition(), MockLocationGateway.position);
    });

    test('con el viaje se acerca a la sede elegida, a 150 km/h', () async {
      controls.simulateTrip = true;
      final start = await kmToCampus();

      clock.advance(const Duration(minutes: 1));
      final afterOne = await kmToCampus();

      expect(afterOne, lessThan(start));
      // 150 km/h son 2,5 km por minuto.
      expect(start - afterOne, closeTo(2.5, 0.05));
    });

    test('al llegar se queda en la sede', () async {
      controls.simulateTrip = true;
      await gateway.currentPosition();

      clock.advance(const Duration(hours: 1));

      expect(await gateway.currentPosition(), campus);
    });

    test('al apagar el viaje vuelve a Miraflores', () async {
      controls.simulateTrip = true;
      await gateway.currentPosition();
      clock.advance(const Duration(minutes: 2));

      controls.simulateTrip = false;

      expect(await gateway.currentPosition(), MockLocationGateway.position);
    });

    test('un viaje nuevo empieza otra vez desde Miraflores', () async {
      controls.simulateTrip = true;
      await gateway.currentPosition();
      clock.advance(const Duration(minutes: 2));
      controls.simulateTrip = false;
      await gateway.currentPosition();

      controls.simulateTrip = true;

      expect(await gateway.currentPosition(), MockLocationGateway.position);
    });

    test('sin sede elegida no hay viaje', () async {
      store.id = null;
      controls.simulateTrip = true;
      clock.advance(const Duration(minutes: 2));

      expect(await gateway.currentPosition(), MockLocationGateway.position);
    });

    test('sin permiso no hay posición, con o sin viaje', () async {
      controls
        ..simulateTrip = true
        ..locationPermission = LocationPermissionStatus.denied;

      expect(await gateway.currentPosition(), isNull);
    });
  });

  group('el ETA durante el viaje', () {
    DeviceRouteEtaEstimator estimator() => DeviceRouteEtaEstimator(
      positionSource: gateway,
      routeProvider: const LocalRouteProvider(),
      trafficProvider: MockTrafficRouteProvider(controls),
    );

    Future<EtaEstimate?> eta({bool traffic = true}) async =>
        (await estimator().estimate(
          EtaEstimationContext(destination: campus, useTraffic: traffic),
        )).valueOrNull;

    test('baja solo a medida que el teléfono se acerca', () async {
      controls.simulateTrip = true;
      final first = await eta();
      clock.advance(const Duration(minutes: 1));
      final second = await eta();
      clock.advance(const Duration(minutes: 1));
      final third = await eta();

      expect(first?.source, EtaSource.traffic);
      expect(second!.minutes.value, lessThan(first!.minutes.value));
      expect(third!.minutes.value, lessThan(second.minutes.value));
    });

    test('con mucho tráfico el viaje tarda más', () async {
      final normal = await eta();
      controls.heavyTraffic = true;
      final heavy = await eta();

      expect(heavy!.minutes.value, greaterThan(normal!.minutes.value));
      expect(
        heavy.minutes.value / normal.minutes.value,
        closeTo(
          MockTrafficRouteProvider.heavyFactor /
              MockTrafficRouteProvider.normalFactor,
          0.15,
        ),
      );
    });

    test(
      'con el proveedor caído baja a la estimación del teléfono, sin error',
      () async {
        controls.routesOutage = true;

        final result = await eta();

        expect(result?.source, EtaSource.device);
        expect(result!.minutes.value % 5, 0);
      },
    );

    test('sin activar el tráfico usa la estimación del teléfono', () async {
      final result = await eta(traffic: false);

      expect(result?.source, EtaSource.device);
    });
  });
}

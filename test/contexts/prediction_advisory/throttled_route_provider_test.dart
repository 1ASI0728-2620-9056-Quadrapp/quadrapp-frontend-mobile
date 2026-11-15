// US14: las consultas al proveedor de mapas se limitan porque se pagan.
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/repositories/route_provider.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/services/throttled_route_provider.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/geo_point.dart';

import '../../helpers/fake_clock.dart';

class _Counting implements RouteProvider {
  int calls = 0;
  RouteTravel? next = const RouteTravel(
    duration: Duration(minutes: 25),
    basis: RouteBasis.traffic,
  );

  @override
  Future<RouteTravel?> travelTime({
    required GeoPoint from,
    required GeoPoint to,
  }) async {
    calls++;
    return next;
  }
}

const _campus = GeoPoint(latitude: -12.1035, longitude: -76.963);
const _other = GeoPoint(latitude: -12.0947, longitude: -77.0516);
const _start = GeoPoint(latitude: -12.1219, longitude: -77.0297);
// ~220 m al norte.
const _near = GeoPoint(latitude: -12.1199, longitude: -77.0297);
// ~1,1 km al norte.
const _far = GeoPoint(latitude: -12.1119, longitude: -77.0297);

void main() {
  late _Counting inner;
  late FakeClock clock;
  late ThrottledRouteProvider provider;

  setUp(() {
    inner = _Counting();
    clock = FakeClock();
    provider = ThrottledRouteProvider(inner, clock);
  });

  test('la primera vez consulta', () async {
    final travel = await provider.travelTime(from: _start, to: _campus);

    expect(inner.calls, 1);
    expect(travel?.duration, const Duration(minutes: 25));
    expect(travel?.basis, RouteBasis.traffic);
  });

  test(
    'entre consultas reutiliza la ruta y la descuenta con el reloj',
    () async {
      await provider.travelTime(from: _start, to: _campus);
      clock.advance(const Duration(minutes: 2));

      final travel = await provider.travelTime(from: _near, to: _campus);

      expect(inner.calls, 1);
      expect(travel?.duration, const Duration(minutes: 23));
    },
  );

  test('pasado el intervalo (3 min) vuelve a consultar', () async {
    await provider.travelTime(from: _start, to: _campus);
    clock.advance(const Duration(minutes: 3));
    inner.next = const RouteTravel(
      duration: Duration(minutes: 19),
      basis: RouteBasis.traffic,
    );

    final travel = await provider.travelTime(from: _start, to: _campus);

    expect(inner.calls, 2);
    expect(travel?.duration, const Duration(minutes: 19));
  });

  test('si se movió más de 500 m consulta antes de tiempo', () async {
    await provider.travelTime(from: _start, to: _campus);
    clock.advance(const Duration(seconds: 30));

    await provider.travelTime(from: _far, to: _campus);

    expect(inner.calls, 2);
  });

  test('otro destino consulta de nuevo', () async {
    await provider.travelTime(from: _start, to: _campus);

    await provider.travelTime(from: _start, to: _other);

    expect(inner.calls, 2);
  });

  test('el tiempo descontado nunca es negativo', () async {
    inner.next = const RouteTravel(
      duration: Duration(minutes: 1),
      basis: RouteBasis.traffic,
    );
    await provider.travelTime(from: _start, to: _campus);
    clock.advance(const Duration(minutes: 2, seconds: 30));

    final travel = await provider.travelTime(from: _near, to: _campus);

    expect(travel?.duration, Duration.zero);
  });

  test(
    'si el proveedor no responde, devuelve null y no usa lo viejo',
    () async {
      await provider.travelTime(from: _start, to: _campus);
      clock.advance(const Duration(minutes: 4));
      inner.next = null;

      final failed = await provider.travelTime(from: _start, to: _campus);
      final again = await provider.travelTime(from: _start, to: _campus);

      expect(failed, isNull);
      expect(again, isNull);
      // Al no haber ruta guardada, cada intento consulta de nuevo.
      expect(inner.calls, 3);
    },
  );
}

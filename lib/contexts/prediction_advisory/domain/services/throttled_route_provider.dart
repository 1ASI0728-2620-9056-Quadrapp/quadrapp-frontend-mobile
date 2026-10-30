import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/repositories/route_provider.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/eta_assumptions.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/geo_point.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';

/// Limita las consultas a un proveedor de mapas, que se pagan por consulta.
///
/// Reutiliza la última respuesta mientras sea reciente
/// ([EtaAssumptions.routeRefreshInterval]) y el conductor no se haya movido
/// ([EtaAssumptions.routeRefreshDistanceMeters]) hacia el mismo destino, y la
/// va **descontando con el reloj monótono**: si la ruta eran 25 minutos hace
/// 2 minutos, ahora quedan 23. Así el ETA baja solo entre consultas, sin red.
///
/// Si el proveedor no responde, devuelve `null` (quien llama cae a la
/// estimación local): una respuesta vieja no se usa como si fuera actual.
class ThrottledRouteProvider implements RouteProvider {
  ThrottledRouteProvider(this._inner, this._clock);

  final RouteProvider _inner;
  final Clock _clock;

  _Cached? _last;

  @override
  Future<RouteTravel?> travelTime({
    required GeoPoint from,
    required GeoPoint to,
  }) async {
    final cached = _last;
    if (cached != null && cached.to == to) {
      final elapsed = _clock.monotonic() - cached.at;
      final moved = cached.from.distanceMetersTo(from);
      if (elapsed < EtaAssumptions.routeRefreshInterval &&
          moved < EtaAssumptions.routeRefreshDistanceMeters) {
        final remaining = cached.travel.duration - elapsed;
        return RouteTravel(
          duration: remaining.isNegative ? Duration.zero : remaining,
          basis: cached.travel.basis,
        );
      }
    }
    final fresh = await _inner.travelTime(from: from, to: to);
    _last = fresh == null
        ? null
        : _Cached(from: from, to: to, travel: fresh, at: _clock.monotonic());
    return fresh;
  }
}

class _Cached {
  const _Cached({
    required this.from,
    required this.to,
    required this.travel,
    required this.at,
  });

  final GeoPoint from;
  final GeoPoint to;
  final RouteTravel travel;
  final Duration at;
}

import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/repositories/route_provider.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/eta_assumptions.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/geo_point.dart';

/// Tiempo de viaje **local**, sin red: distancia en línea recta × factor de
/// desvío ÷ velocidad media supuesta (`EtaAssumptions`). Es una aproximación,
/// sin tráfico: la posición no sale del dispositivo.
class LocalRouteProvider implements RouteProvider {
  const LocalRouteProvider();

  @override
  Future<RouteTravel?> travelTime({
    required GeoPoint from,
    required GeoPoint to,
  }) async {
    final routeKm = from.distanceKmTo(to) * EtaAssumptions.detourFactor;
    final hours = routeKm / EtaAssumptions.averageSpeedKmh;
    return RouteTravel(
      duration: Duration(seconds: (hours * 3600).round()),
      basis: RouteBasis.distance,
    );
  }
}

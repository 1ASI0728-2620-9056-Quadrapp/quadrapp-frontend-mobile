import 'package:quadrapp_mobile/app/mocks/mock_controls.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/repositories/route_provider.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/geo_point.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/infrastructure/eta/local_route_provider.dart';

/// El proveedor de mapas de los mocks: el tiempo local con el tráfico encima
/// (×1,3, o ×1,8 con [MockControls.heavyTraffic]) y sin red. Con
/// [MockControls.routesOutage] no responde, como un servicio caído.
class MockTrafficRouteProvider implements RouteProvider {
  const MockTrafficRouteProvider(this._controls);

  static const double normalFactor = 1.3;
  static const double heavyFactor = 1.8;

  final MockControls _controls;

  @override
  Future<RouteTravel?> travelTime({
    required GeoPoint from,
    required GeoPoint to,
  }) async {
    if (_controls.routesOutage) return null;
    final local = await const LocalRouteProvider().travelTime(
      from: from,
      to: to,
    );
    if (local == null) return null;
    final factor = _controls.heavyTraffic ? heavyFactor : normalFactor;
    return RouteTravel(
      duration: Duration(seconds: (local.duration.inSeconds * factor).round()),
      basis: RouteBasis.traffic,
    );
  }
}

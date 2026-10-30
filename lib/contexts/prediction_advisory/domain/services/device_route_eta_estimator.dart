import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/entities/eta_estimate.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/repositories/position_source.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/repositories/route_provider.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/services/eta_estimator.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/eta_assumptions.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/eta_minutes.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/geo_point.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// ETA automático: la posición del dispositivo y un tiempo de viaje.
///
/// El tiempo sale, en este orden, de:
/// 1. el proveedor de mapas con tráfico, solo si el conductor lo activó
///    (`EtaEstimationContext.useTraffic`) y hay uno;
/// 2. la estimación local, sin red, si no hay proveedor, no respondió (sin
///    clave, sin red, fallo) o el conductor no lo activó.
///
/// Con tráfico el resultado se redondea al minuto; con la estimación local, a
/// bloques de 5 minutos ([EtaAssumptions.roundingBlockMinutes]). Devuelve solo
/// minutos. Al proveedor de mapas solo viaja el origen redondeado a unos 100 m
/// ([EtaAssumptions.originDecimals]).
///
/// Si no se puede estimar (sin coordenadas de destino, permiso negado, sin
/// posición) devuelve `Success(null)` **sin error**: la app sigue con el modo
/// manual. Un tiempo mayor que el máximo admitido es un `Err` (el conductor
/// está demasiado lejos para pedir la asesoría).
class DeviceRouteEtaEstimator implements EtaEstimator {
  const DeviceRouteEtaEstimator({
    required this._positionSource,
    required this._routeProvider,
    this._trafficProvider,
  });

  final PositionSource _positionSource;

  /// La estimación local: nunca devuelve `null`.
  final RouteProvider _routeProvider;

  /// El proveedor de mapas; `null` si no hay (sin clave).
  final RouteProvider? _trafficProvider;

  @override
  Future<Result<EtaEstimate?>> estimate(EtaEstimationContext context) async {
    final destination = context.destination;
    if (destination == null) return const Success(null);
    final RouteTravel? travel;
    try {
      final position = await _positionSource.currentPosition();
      if (position == null) return const Success(null);
      travel = await _travel(position, destination, context.useTraffic);
    } on Object {
      // Cualquier falla de la plataforma (GPS, permisos) cae al modo manual.
      return const Success(null);
    }
    if (travel == null) return const Success(null);
    final traffic = travel.basis == RouteBasis.traffic;
    final minutes = roundTo(
      travel.duration.inSeconds / 60,
      traffic
          ? EtaAssumptions.trafficRoundingMinutes
          : EtaAssumptions.roundingBlockMinutes,
    );
    return EtaMinutes.create(minutes).map<EtaEstimate?>(
      (eta) => EtaEstimate(
        minutes: eta,
        source: traffic ? EtaSource.traffic : EtaSource.device,
      ),
    );
  }

  Future<RouteTravel?> _travel(
    GeoPoint position,
    GeoPoint destination,
    bool useTraffic,
  ) async {
    final provider = _trafficProvider;
    if (useTraffic && provider != null) {
      try {
        final withTraffic = await provider.travelTime(
          from: position.coarsened(EtaAssumptions.originDecimals),
          to: destination,
        );
        if (withTraffic != null) return withTraffic;
      } on Object {
        // El proveedor falló: se sigue con la estimación local.
      }
    }
    return _routeProvider.travelTime(from: position, to: destination);
  }

  /// Redondea al múltiplo de [block] minutos más cercano.
  static int roundTo(double minutes, int block) =>
      (minutes / block).round() * block;

  /// Redondea al múltiplo de [EtaAssumptions.roundingBlockMinutes] más cercano.
  static int roundToBlock(double minutes) =>
      roundTo(minutes, EtaAssumptions.roundingBlockMinutes);
}

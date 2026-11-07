// US13 (mapa de la llegada); TS08 (la posición no llega a Quadrapp)
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/repositories/location_permission_gateway.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/repositories/position_source.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/eta_assumptions.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/geo_point.dart';
import 'package:quadrapp_mobile/core/network/failure_mapper.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

/// La posición del conductor redondeada a unos 100 m, para dibujarla en el
/// mapa de Google (el mismo redondeo que el origen del tráfico). `null` si no
/// hay permiso o no se puede obtener: **no** pide el permiso. Nunca va a
/// Quadrapp ni se guarda.
class GetApproximatePosition implements UseCase<GeoPoint?, NoParams> {
  const GetApproximatePosition({
    required this._permission,
    required this._positions,
  });

  final LocationPermissionGateway _permission;
  final PositionSource _positions;

  @override
  Future<Result<GeoPoint?>> call(NoParams params) => guardResult(() async {
    if (await _permission.status() != LocationPermissionStatus.granted) {
      return null;
    }
    final position = await _positions.currentPosition();
    return position?.coarsened(EtaAssumptions.originDecimals);
  });
}

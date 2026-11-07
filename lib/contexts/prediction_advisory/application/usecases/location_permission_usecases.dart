// US13 (docs/05 regla 11)
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/repositories/location_permission_gateway.dart';
import 'package:quadrapp_mobile/core/network/failure_mapper.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

/// Consulta el estado del permiso de ubicación (sin mostrar nada).
class GetLocationPermissionStatus
    implements UseCase<LocationPermissionStatus, NoParams> {
  const GetLocationPermissionStatus(this._gateway);

  final LocationPermissionGateway _gateway;

  @override
  Future<Result<LocationPermissionStatus>> call(NoParams params) =>
      guardResult(_gateway.status);
}

/// Pide el permiso de ubicación. La pantalla debe llamarlo **solo después** de
/// explicar que únicamente se envían los minutos de llegada; nunca al abrir la
/// app. Si se niega, la app sigue en modo manual sin errores.
class RequestLocationPermission
    implements UseCase<LocationPermissionStatus, NoParams> {
  const RequestLocationPermission(this._gateway);

  final LocationPermissionGateway _gateway;

  @override
  Future<Result<LocationPermissionStatus>> call(NoParams params) =>
      guardResult(_gateway.request);
}

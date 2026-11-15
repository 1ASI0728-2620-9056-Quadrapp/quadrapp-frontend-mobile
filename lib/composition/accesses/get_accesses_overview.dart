// US19, US29
import 'package:quadrapp_mobile/composition/accesses/accesses_overview.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

/// Lectura de los accesos vehiculares de un estacionamiento.
// ignore: one_member_abstracts
abstract interface class AccessesOverviewReader {
  /// `ForbiddenFailure` si la sesión es de un conductor (403);
  /// `NotFoundFailure` si el estacionamiento no existe.
  Future<Result<AccessesOverview>> read(LotId lotId);
}

/// Los accesos vehiculares de un estacionamiento: flujo en vivo, estado de
/// cada acceso y configuración propia.
class GetAccessesOverview implements UseCase<AccessesOverview, LotId> {
  const GetAccessesOverview(this._reader);

  final AccessesOverviewReader _reader;

  @override
  Future<Result<AccessesOverview>> call(LotId lotId) => _reader.read(lotId);
}

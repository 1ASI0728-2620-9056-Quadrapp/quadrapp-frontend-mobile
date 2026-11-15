import 'package:quadrapp_mobile/app/mocks/mock_console_json.dart';
import 'package:quadrapp_mobile/app/mocks/mock_errors.dart';
import 'package:quadrapp_mobile/app/mocks/mock_world.dart';
import 'package:quadrapp_mobile/composition/accesses/accesses_overview_dto.dart';
import 'package:quadrapp_mobile/composition/accesses/accesses_overview_remote_datasource.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

/// `GET /console/accesses` desde [MockWorld]: arma el JSON con el formato de
/// docs/07 y lo lee con el mismo DTO que el datasource HTTP. Solo atiende a un
/// rol de Operación (403 a un conductor); un estacionamiento inexistente
/// responde 404. Uno sin distribución publicada sí responde: sus accesos no
/// dependen de la distribución.
class MockAccessesOverviewRemoteDataSource
    implements AccessesOverviewRemoteDataSource {
  const MockAccessesOverviewRemoteDataSource(this._world, this._callerRole);

  final MockWorld _world;
  final String? Function() _callerRole;

  @override
  Future<AccessesOverviewDto> fetch(LotId lotId) async {
    await _world.gateConsole(_callerRole());
    final lot = _world.lot(lotId.value);
    if (lot == null) throw mockHttpError(404, title: 'Not Found');
    return AccessesOverviewDto.fromJson(mockAccessesJson(_world, lot));
  }
}

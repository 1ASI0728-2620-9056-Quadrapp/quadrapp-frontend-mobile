import 'package:quadrapp_mobile/app/mocks/mock_console_json.dart';
import 'package:quadrapp_mobile/app/mocks/mock_errors.dart';
import 'package:quadrapp_mobile/app/mocks/mock_world.dart';
import 'package:quadrapp_mobile/composition/shift/shift_overview_dto.dart';
import 'package:quadrapp_mobile/composition/shift/shift_overview_remote_datasource.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

/// `GET /console/overview` desde [MockWorld]: arma el JSON con el formato de
/// docs/07 y lo lee con el mismo DTO que el datasource HTTP. Solo atiende a un
/// rol de Operación (403 a un conductor, TS17 esc. 2); un estacionamiento sin
/// distribución publicada responde 404.
class MockShiftOverviewRemoteDataSource
    implements ShiftOverviewRemoteDataSource {
  const MockShiftOverviewRemoteDataSource(this._world, this._callerRole);

  final MockWorld _world;
  final String? Function() _callerRole;

  @override
  Future<ShiftOverviewDto> fetch(LotId lotId) async {
    await _world.gateConsole(_callerRole());
    final lot = _world.lot(lotId.value);
    if (lot == null || !lot.hasLayout) {
      throw mockHttpError(404, title: 'Not Found');
    }
    return ShiftOverviewDto.fromJson(mockOverviewJson(_world, lot));
  }
}

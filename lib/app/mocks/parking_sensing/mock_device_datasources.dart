import 'package:quadrapp_mobile/app/mocks/mock_console_json.dart';
import 'package:quadrapp_mobile/app/mocks/mock_errors.dart';
import 'package:quadrapp_mobile/app/mocks/mock_world.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/infrastructure/datasources/device_remote_datasource.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/infrastructure/dto/device_dtos.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

const _types = {'SPACE_SENSOR', 'PASS_SENSOR', 'GATEWAY'};

Never _invalid(String field, String code, {int status = 400}) =>
    throw mockHttpError(
      status,
      title: status == 409 ? 'Conflict' : 'Bad Request',
      extra: {
        'errors': {
          field: [code],
        },
      },
    );

/// Dispositivos desde [MockWorld]. Arma el JSON con el formato de docs/07 y lo
/// lee con el mismo DTO que el datasource HTTP. Solo atiende a un rol de
/// Operación: a un conductor le responde 403 (el segundo parámetro da el rol
/// de quien llama).
class MockDeviceRemoteDataSource implements DeviceRemoteDataSource {
  const MockDeviceRemoteDataSource(this._world, this._callerRole);

  final MockWorld _world;
  final String? Function() _callerRole;

  @override
  Future<DeviceHealthDto> health(LotId lotId) async {
    await _world.gateConsole(_callerRole());
    final lot = _world.lot(lotId.value);
    if (lot == null) throw mockHttpError(404, title: 'Not Found');
    return DeviceHealthDto.fromJson(mockDevicesHealthJson(_world, lot));
  }

  /// Valida como el servidor: tipo conocido, identificador no vacío y único
  /// (409), intervalo mayor que cero y `directional` obligatorio solo con
  /// `PASS_SENSOR`.
  @override
  Future<DeviceDto> register(RegisterDeviceRequestDto request) async {
    await _world.gateConsole(_callerRole());
    if (_world.controls.forceDeviceRegisterFailure) {
      throw mockHttpError(500, title: 'Internal Server Error');
    }
    final lot = _world.lot(request.lotId);
    if (lot == null) throw mockHttpError(404, title: 'Not Found');
    if (!_types.contains(request.type)) _invalid('type', 'invalid');
    final hardwareId = request.hardwareId.trim();
    if (hardwareId.isEmpty || hardwareId.length > 80) {
      _invalid('hardwareId', 'invalid');
    }
    if (request.expectedReportIntervalSec <= 0) {
      _invalid('expectedReportIntervalSec', 'positive');
    }
    final isPass = request.type == 'PASS_SENSOR';
    if (isPass && request.directional == null) {
      _invalid('directional', 'required');
    }
    if (!isPass && request.directional != null) {
      _invalid('directional', 'not-allowed');
    }
    if (_world.hardwareIdTaken(hardwareId)) {
      _invalid('hardwareId', 'duplicate', status: 409);
    }
    final device = _world.registerDevice(
      lotId: lot.id,
      type: request.type,
      hardwareId: hardwareId,
      expectedReportIntervalSec: request.expectedReportIntervalSec,
      directional: request.directional,
    );
    return DeviceDto.fromJson(mockDeviceJson(_world, device));
  }

  @override
  Future<void> decommission(DeviceId id) async {
    await _world.gateConsole(_callerRole());
    if (!_world.decommissionDevice(id.value)) {
      throw mockHttpError(404, title: 'Not Found');
    }
  }
}

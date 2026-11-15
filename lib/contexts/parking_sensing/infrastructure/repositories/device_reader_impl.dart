import 'package:quadrapp_mobile/contexts/parking_sensing/domain/entities/device_inventory.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/domain/repositories/device_reader.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/infrastructure/datasources/device_remote_datasource.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/infrastructure/mappers/device_mapper.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/network/failure_mapper.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';

/// Lee la salud de los dispositivos y convierte cualquier falla de
/// infraestructura en una `Failure` (US20, TS10). Sin caché: es una consulta
/// operativa que solo vale si es actual.
class DeviceReaderImpl implements DeviceReader {
  const DeviceReaderImpl({
    required this._remote,
    required this._mapper,
    required this._clock,
  });

  final DeviceRemoteDataSource _remote;
  final DeviceMapper _mapper;
  final Clock _clock;

  @override
  Future<Result<DeviceInventory>> read(LotId lotId) => guardResult(() async {
    final dto = await _remote.health(lotId);
    return _mapper.toInventory(dto, lotId, receivedAt: _clock.monotonic());
  });
}

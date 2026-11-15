import 'package:quadrapp_mobile/contexts/parking_sensing/domain/entities/device.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/domain/entities/new_device.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/domain/repositories/device_registry.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/infrastructure/datasources/device_remote_datasource.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/infrastructure/mappers/device_mapper.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/network/failure_mapper.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// Registra y da de baja dispositivos (US32). Un 404 al dar de baja es éxito:
/// el dispositivo ya no existe, que era el objetivo (docs/07).
class DeviceRegistryImpl implements DeviceRegistry {
  const DeviceRegistryImpl({required this._remote, required this._mapper});

  final DeviceRemoteDataSource _remote;
  final DeviceMapper _mapper;

  @override
  Future<Result<Device>> register(NewDevice device) => guardResult(() async {
    final dto = await _remote.register(_mapper.toRequest(device));
    return _mapper.toDevice(dto, device.lotId);
  });

  @override
  Future<Result<void>> decommission(DeviceId id) async {
    final result = await guardResult(() => _remote.decommission(id));
    return switch (result) {
      Err(failure: NotFoundFailure()) => const Success<void>(null),
      _ => result,
    };
  }
}

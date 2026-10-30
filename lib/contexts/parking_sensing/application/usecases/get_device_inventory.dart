// US20, TS10
import 'package:quadrapp_mobile/contexts/parking_sensing/domain/entities/device_inventory.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/domain/repositories/device_reader.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

/// Los dispositivos de un estacionamiento con su salud.
class GetDeviceInventory implements UseCase<DeviceInventory, LotId> {
  const GetDeviceInventory(this._reader);

  final DeviceReader _reader;

  @override
  Future<Result<DeviceInventory>> call(LotId lotId) => _reader.read(lotId);
}

// US32 (esc. 1)
import 'package:quadrapp_mobile/contexts/parking_sensing/domain/entities/device.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/domain/entities/new_device.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/domain/repositories/device_registry.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

/// Registra un dispositivo en el estacionamiento (ya validado en [NewDevice]).
class RegisterDevice implements UseCase<Device, NewDevice> {
  const RegisterDevice(this._registry);

  final DeviceRegistry _registry;

  @override
  Future<Result<Device>> call(NewDevice device) => _registry.register(device);
}

// US32 (esc. 3)
import 'package:quadrapp_mobile/contexts/parking_sensing/domain/repositories/device_registry.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

/// Da de baja un dispositivo: deja de aceptar eventos.
class DecommissionDevice implements UseCase<void, DeviceId> {
  const DecommissionDevice(this._registry);

  final DeviceRegistry _registry;

  @override
  Future<Result<void>> call(DeviceId id) => _registry.decommission(id);
}

/// API pública del contexto `parking_sensing`: inventario y salud de
/// dispositivos para la experiencia de Operación (US20, US32 esc. 1 y 3,
/// TS10). Nada más.
library;

export 'application/usecases/decommission_device.dart';
export 'application/usecases/get_device_inventory.dart';
export 'application/usecases/register_device.dart';
export 'domain/entities/device.dart';
export 'domain/entities/device_inventory.dart';
export 'domain/entities/new_device.dart';
export 'domain/value_objects/device_status.dart';
export 'domain/value_objects/device_type.dart';

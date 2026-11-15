/// Tipo de dispositivo del inventario (docs/06 `devices.type`).
enum DeviceType {
  /// Sensor de un espacio (US18: se asigna a un espacio desde la consola web).
  spaceSensor,

  /// Sensor de paso de un acceso, para el flujo de entradas y salidas (US19).
  passSensor,

  /// Gateway: concentra los sensores y publica sus eventos.
  gateway,
}

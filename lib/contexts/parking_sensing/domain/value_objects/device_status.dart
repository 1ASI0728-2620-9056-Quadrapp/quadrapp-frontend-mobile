/// Estado de un dispositivo (docs/06 `devices.status`, US20, TS10).
enum DeviceStatus {
  /// Reporta con normalidad (US20 esc. 1 y 3).
  operational,

  /// Dejó de reportar dentro de su intervalo esperado (US20 esc. 2, TS10
  /// esc. 2): su espacio queda `UNKNOWN`.
  unreachable,

  /// Su batería bajó del umbral del estacionamiento (TS10 esc. 3): marcado
  /// para mantenimiento y su espacio queda `UNKNOWN`.
  lowBattery,

  /// Dado de baja (US32 esc. 3): ya no acepta eventos; sigue en el inventario
  /// como historial.
  decommissioned,
}

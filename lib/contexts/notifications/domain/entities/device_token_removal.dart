// US02 (esc. 3)
/// Cómo terminó el intento de dar de baja el token push de este dispositivo.
enum DeviceTokenRemoval {
  /// No había token registrado ni baja pendiente.
  nothingToRemove,

  /// El servidor dio de baja el token (o ya no existía: un 404 cuenta como
  /// éxito).
  removed,

  /// No se pudo (sin red, error del servidor, demasiadas solicitudes): el token
  /// queda en la baja pendiente para reintentar.
  pending,

  /// El servidor rechazó la baja de una forma que reintentar no arregla: se
  /// descarta el registro.
  abandoned,
}

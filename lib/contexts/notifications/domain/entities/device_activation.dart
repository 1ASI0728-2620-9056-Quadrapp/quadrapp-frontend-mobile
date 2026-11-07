// US33
/// Cómo terminó el intento de dejar este dispositivo como destino de las
/// alertas (US33 esc. 2). Nunca es un error de pantalla: la suscripción y las
/// preferencias valen aunque el dispositivo no quede habilitado.
enum DeviceActivation {
  /// El token del dispositivo está registrado en el servidor.
  registered,

  /// El conductor no concedió el permiso de notificaciones.
  permissionDenied,

  /// El sistema ya no deja pedir el permiso: hay que activarlo desde los
  /// ajustes del teléfono.
  permissionBlocked,

  /// El permiso está concedido, pero el proveedor no entregó un token.
  tokenUnavailable,

  /// El permiso está concedido, pero el servidor no pudo registrar el token
  /// (por ejemplo, sin conexión). Se puede reintentar.
  registrationFailed,
}

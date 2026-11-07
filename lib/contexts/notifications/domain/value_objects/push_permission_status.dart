/// Estado del permiso de notificaciones del sistema (Android 13 o superior;
/// en versiones anteriores el permiso ya está concedido).
enum PushPermissionStatus {
  granted,

  /// Aún no concedido, pero el sistema todavía deja pedirlo.
  denied,

  /// El sistema ya no muestra el diálogo: solo se puede activar desde los
  /// ajustes del teléfono.
  deniedForever,
}

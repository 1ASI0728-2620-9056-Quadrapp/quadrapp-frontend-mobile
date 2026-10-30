/// Estado del permiso de ubicación (en primer plano).
enum LocationPermissionStatus {
  granted,

  /// Aún no se concedió; se puede pedir (después de explicar para qué).
  denied,

  /// El conductor lo negó para siempre: solo se puede cambiar en Ajustes.
  deniedForever,

  /// La ubicación del teléfono está apagada.
  serviceDisabled,
}

/// El permiso de ubicación. Se pide con una explicación previa, nunca al abrir
/// la app. Si se niega, se usa el modo manual sin mostrar errores.
abstract interface class LocationPermissionGateway {
  Future<LocationPermissionStatus> status();

  /// Muestra el diálogo del sistema y devuelve el estado resultante.
  Future<LocationPermissionStatus> request();
}

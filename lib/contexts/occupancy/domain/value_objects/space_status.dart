/// Estado de un espacio.
///
/// Un espacio `unknown` nunca cuenta como disponible y se muestra distinto a
/// libre y ocupado (US08).
enum SpaceStatus {
  free,
  occupied,
  unknown;

  /// Solo un espacio libre cuenta como disponible.
  bool get isAvailable => this == SpaceStatus.free;
}

/// Por qué un espacio no tiene información confiable (US08).
enum UnknownReason { noHeartbeat, lowBattery, noSensor }

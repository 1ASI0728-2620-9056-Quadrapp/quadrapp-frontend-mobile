/// Tono semántico de un estado. Nunca se comunica solo con color: cada
/// componente lo acompaña con forma o patrón y con texto.
enum QaTone {
  /// Libre / disponible / probabilidad alta (turquesa).
  free,

  /// Casi lleno / advertencia / limitada (ámbar).
  limited,

  /// Lleno / saturación / error / probabilidad baja (coral).
  full,

  /// Espacio ocupado (un neutro slate, nunca rojo).
  occupied,

  /// Sin datos (siempre con rayado).
  unknown,
}

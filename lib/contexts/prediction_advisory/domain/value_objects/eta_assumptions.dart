/// Supuestos de la estimación del ETA. Viven en un solo lugar, con nombre y
/// documentados, para poder ajustarlos sin buscar números sueltos.
abstract final class EtaAssumptions {
  /// Cuánto más largo que la línea recta es un trayecto urbano típico (calles
  /// que no van en línea recta, giros, semáforos). 1.35 = 35 % más. Solo para
  /// la estimación **local** (sin tráfico).
  static const double detourFactor = 1.35;

  /// Velocidad media supuesta del tráfico urbano de Lima, en km/h. Solo para la
  /// estimación local.
  static const double averageSpeedKmh = 25;

  /// La estimación local se redondea a bloques de este tamaño, en minutos (al
  /// múltiplo más cercano), para no aparentar una precisión que no existe.
  static const int roundingBlockMinutes = 5;

  /// Un tiempo calculado con tráfico se redondea al minuto más cercano.
  static const int trafficRoundingMinutes = 1;

  /// Cuánto cambia el ETA, en minutos, para que se publique uno nuevo (y se
  /// recalcule la asesoría). Evita parpadeos por variaciones pequeñas del
  /// tráfico o del GPS. Siempre se publica al llegar (0 minutos).
  static const int publishThresholdMinutes = 2;

  /// Cada cuánto, como mucho, se consulta al proveedor de mapas (cada consulta
  /// tiene costo). Entre consultas, el tiempo de viaje baja con el reloj.
  static const Duration routeRefreshInterval = Duration(minutes: 3);

  /// Cuánto debe moverse el conductor, en metros, para consultar al proveedor
  /// de mapas antes de que pase [routeRefreshInterval].
  static const double routeRefreshDistanceMeters = 500;

  /// Decimales con que se envía la posición al proveedor de mapas: 3 son unos
  /// 100 m. Basta para el tiempo de viaje y no revela el punto exacto.
  static const int originDecimals = 3;
}

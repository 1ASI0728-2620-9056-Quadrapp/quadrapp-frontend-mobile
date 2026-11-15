/// Horizontes de predicción admitidos: 15, 30, 45 y 60 minutos (US10).
enum ForecastHorizon {
  min15(15),
  min30(30),
  min45(45),
  min60(60);

  const ForecastHorizon(this.minutes);

  final int minutes;

  /// El horizonte con esos minutos, o `null` si no es uno de los admitidos.
  static ForecastHorizon? fromMinutes(int minutes) {
    for (final horizon in values) {
      if (horizon.minutes == minutes) return horizon;
    }
    return null;
  }

  /// El horizonte más cercano a [minutes] (empate: el mayor; más de 60: 60).
  static ForecastHorizon nearestTo(int minutes) {
    var best = values.first;
    for (final horizon in values) {
      final distance = (horizon.minutes - minutes).abs();
      final bestDistance = (best.minutes - minutes).abs();
      if (distance < bestDistance ||
          (distance == bestDistance && horizon.minutes > best.minutes)) {
        best = horizon;
      }
    }
    return best;
  }
}

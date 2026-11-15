/// Cómo se agrega la ocupación histórica (TS11 esc. 1): por hora o por día.
enum OccupancyGranularity {
  hour,
  day;

  /// La que corresponde a un rango: por hora si cabe en un día; si no, por
  /// día (30 días por hora serían 720 puntos que nadie lee en un teléfono).
  static OccupancyGranularity forLength(Duration length) =>
      length <= const Duration(days: 1) ? hour : day;
}

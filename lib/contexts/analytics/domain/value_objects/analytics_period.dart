import 'package:equatable/equatable.dart';

/// El periodo que se consulta en Analítica (US21 esc. 1, US34 esc. 1).
enum AnalyticsPeriod {
  /// Desde la medianoche de hoy (hora de Lima) hasta ahora.
  today(1),

  /// Los últimos 7 días, contando hoy.
  last7Days(7),

  /// Los últimos 30 días, contando hoy.
  last30Days(30);

  const AnalyticsPeriod(this.days);

  /// Cuántos días calendario abarca, contando hoy.
  final int days;
}

/// Un rango de fechas válido: [from] es anterior a [to] (TS11 esc. 2). Ambos
/// en UTC.
class AnalyticsRange extends Equatable {
  const AnalyticsRange._(this.from, this.to);

  /// El rango de [period] que termina en [now]: empieza a la medianoche del
  /// primer día del periodo en la zona horaria de [utcOffset] (America/Lima,
  /// UTC−5, sin horario de verano).
  factory AnalyticsRange.forPeriod(
    AnalyticsPeriod period, {
    required DateTime now,
    required Duration utcOffset,
  }) {
    final end = now.toUtc();
    final local = end.add(utcOffset);
    final firstDay = DateTime.utc(
      local.year,
      local.month,
      local.day - (period.days - 1),
    );
    return AnalyticsRange._(firstDay.subtract(utcOffset), end);
  }

  /// El rango de [from] a [to], o `null` si [from] no es anterior a [to].
  static AnalyticsRange? of(DateTime from, DateTime to) {
    final start = from.toUtc();
    final end = to.toUtc();
    if (!start.isBefore(end)) return null;
    return AnalyticsRange._(start, end);
  }

  /// Los días calendario completos de [firstDay] a [lastDay] (ambos
  /// incluidos, de medianoche a medianoche en [utcOffset]), o `null` si
  /// [lastDay] es anterior a [firstDay]. Las fechas se leen por su año, mes y
  /// día (lo que devuelve un selector de fechas).
  static AnalyticsRange? days(
    DateTime firstDay,
    DateTime lastDay, {
    required Duration utcOffset,
  }) {
    final start = DateTime.utc(firstDay.year, firstDay.month, firstDay.day);
    final end = DateTime.utc(lastDay.year, lastDay.month, lastDay.day + 1);
    return of(start.subtract(utcOffset), end.subtract(utcOffset));
  }

  final DateTime from;
  final DateTime to;

  Duration get length => to.difference(from);

  @override
  List<Object?> get props => [from, to];
}

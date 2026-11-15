import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// Hora del día (hora y minuto), sin fecha ni zona: es la hora local de Lima
/// en la que el conductor suele llegar (US33). Se compara por minutos
/// transcurridos desde la medianoche.
class ClockTime extends Equatable implements Comparable<ClockTime> {
  const ClockTime._(this.minutesOfDay);

  /// Hora válida: `hour` entre 0 y 23, `minute` entre 0 y 59.
  static Result<ClockTime> create(int hour, int minute) {
    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      return const Err(
        ValidationFailure('La hora debe estar entre 00:00 y 23:59.'),
      );
    }
    return Success(ClockTime._(hour * 60 + minute));
  }

  final int minutesOfDay;

  int get hour => minutesOfDay ~/ 60;

  int get minute => minutesOfDay % 60;

  bool isBefore(ClockTime other) => minutesOfDay < other.minutesOfDay;

  @override
  int compareTo(ClockTime other) => minutesOfDay.compareTo(other.minutesOfDay);

  @override
  List<Object?> get props => [minutesOfDay];
}

import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/value_objects/clock_time.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// Franja horaria de una suscripción (US33): `from` es estrictamente anterior
/// a `to` y no cruza la medianoche.
class AlertTimeSlot extends Equatable {
  const AlertTimeSlot._({required this.from, required this.to});

  static Result<AlertTimeSlot> create({
    required ClockTime from,
    required ClockTime to,
  }) {
    if (!from.isBefore(to)) {
      return const Err(
        ValidationFailure('La hora de fin debe ser posterior a la de inicio.', {
          'to': ['after-from'],
        }),
      );
    }
    return Success(AlertTimeSlot._(from: from, to: to));
  }

  final ClockTime from;
  final ClockTime to;

  @override
  List<Object?> get props => [from, to];
}

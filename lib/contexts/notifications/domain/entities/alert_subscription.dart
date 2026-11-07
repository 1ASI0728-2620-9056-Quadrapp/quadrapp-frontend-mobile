// US23, US33
import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/value_objects/alert_day.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/value_objects/alert_time_slot.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/value_objects/clock_time.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// Una suscripción activa del conductor a las alertas de un estacionamiento en
/// una franja horaria (US33). El estacionamiento se referencia solo por su id.
class AlertSubscription extends Equatable {
  const AlertSubscription({
    required this.id,
    required this.lotId,
    required this.days,
    required this.slot,
    this.active = true,
  });

  final AlertSubscriptionId id;
  final LotId lotId;

  /// Días de la semana, de lunes a domingo, sin repetidos y al menos uno.
  final List<AlertDay> days;
  final AlertTimeSlot slot;

  /// Una franja desactivada se conserva (para reactivarla) pero no envía
  /// alertas (US33 esc. 3).
  final bool active;

  AlertSubscription copyWith({bool? active}) => AlertSubscription(
    id: id,
    lotId: lotId,
    days: days,
    slot: slot,
    active: active ?? this.active,
  );

  @override
  List<Object?> get props => [id.value, lotId.value, days, slot, active];
}

/// Una suscripción que aún no existe en el servidor: ya cumple las reglas del
/// dominio (1 a 7 días distintos, y `from` anterior a `to`).
class AlertSubscriptionDraft extends Equatable {
  const AlertSubscriptionDraft._({
    required this.lotId,
    required this.days,
    required this.slot,
  });

  /// Valida y arma la suscripción. [days] usa el número del contrato (1 =
  /// lunes ... 7 = domingo); se ordenan y se quitan los repetidos.
  static Result<AlertSubscriptionDraft> create({
    required LotId lotId,
    required Iterable<int> days,
    required ClockTime from,
    required ClockTime to,
  }) {
    final parsed = <AlertDay>{};
    for (final number in days) {
      final day = AlertDay.fromIsoNumber(number);
      if (day == null) {
        return const Err(
          ValidationFailure('Los días deben estar entre 1 y 7.', {
            'days': ['1..7'],
          }),
        );
      }
      parsed.add(day);
    }
    if (parsed.isEmpty) {
      return const Err(
        ValidationFailure('Elige al menos un día.', {
          'days': ['required'],
        }),
      );
    }
    return AlertTimeSlot.create(from: from, to: to).map(
      (slot) => AlertSubscriptionDraft._(
        lotId: lotId,
        days: parsed.toList()
          ..sort((a, b) => a.isoNumber.compareTo(b.isoNumber)),
        slot: slot,
      ),
    );
  }

  final LotId lotId;
  final List<AlertDay> days;
  final AlertTimeSlot slot;

  @override
  List<Object?> get props => [lotId.value, days, slot];
}

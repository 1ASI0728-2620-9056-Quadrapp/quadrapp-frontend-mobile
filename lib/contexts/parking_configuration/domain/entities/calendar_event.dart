import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// Qué es una entrada del calendario del campus (docs/06
/// `calendar_events.type`, US35).
enum CalendarEventType {
  /// Periodo de clases (esc. 1).
  classes,

  /// Periodo de exámenes (esc. 1).
  exams,

  /// Receso o día sin clases (esc. 1).
  recess,

  /// Evento especial de alta afluencia (esc. 2).
  campusEvent;

  /// Los periodos académicos ocupan días completos; un evento, un horario.
  bool get isAcademicPeriod => this != campusEvent;
}

/// Cuánto se espera que cambie la demanda (docs/06 `calendar_events.impact`).
enum DemandImpact { low, medium, high }

/// Una entrada del calendario del campus: insumo de la predicción (US35). El
/// alcance va de lo general a lo particular: todo el campus (sin
/// estacionamiento), un estacionamiento o una de sus zonas.
class CalendarEvent extends Equatable {
  const CalendarEvent({
    required this.id,
    required this.type,
    required this.name,
    required this.impact,
    required this.startsAt,
    required this.endsAt,
    this.lotId,
    this.lotName,
    this.zoneId,
    this.zoneName,
  });

  final CalendarEventId id;
  final CalendarEventType type;
  final String name;
  final DemandImpact impact;

  /// Inicio y fin (UTC); el fin es posterior al inicio.
  final DateTime startsAt;
  final DateTime endsAt;

  /// `null`: todo el campus.
  final LotId? lotId;
  final String? lotName;

  /// `null`: todo el estacionamiento (o todo el campus).
  final ZoneId? zoneId;
  final String? zoneName;

  bool get isCampusWide => lotId == null;

  /// ¿Ya terminó a la hora [now]?
  bool isOver(DateTime now) => !now.isBefore(endsAt);

  @override
  List<Object?> get props => [
    id.value,
    type,
    name,
    impact,
    startsAt,
    endsAt,
    lotId?.value,
    lotName,
    zoneId?.value,
    zoneName,
  ];
}

/// Por qué una entrada nueva no sería válida.
enum CalendarEventError {
  /// Falta el nombre.
  nameMissing,

  /// El nombre pasa de [NewCalendarEvent.maxNameLength] caracteres.
  nameTooLong,

  /// El fin no es posterior al inicio (docs/06 lo exige con un `CHECK`).
  endsBeforeStarts,

  /// Hay zona sin estacionamiento (docs/06 lo exige con un `CHECK`).
  zoneWithoutLot,
}

/// Una entrada por registrar (US35 esc. 1 y 2).
class NewCalendarEvent extends Equatable {
  const NewCalendarEvent._({
    required this.type,
    required this.name,
    required this.impact,
    required this.startsAt,
    required this.endsAt,
    this.lotId,
    this.zoneId,
  });

  /// `calendar_events.name` (docs/06).
  static const int maxNameLength = 120;

  static Set<CalendarEventError> validate({
    required String name,
    required DateTime startsAt,
    required DateTime endsAt,
    LotId? lotId,
    ZoneId? zoneId,
  }) {
    final trimmed = name.trim();
    return {
      if (trimmed.isEmpty) CalendarEventError.nameMissing,
      if (trimmed.length > maxNameLength) CalendarEventError.nameTooLong,
      if (!endsAt.isAfter(startsAt)) CalendarEventError.endsBeforeStarts,
      if (zoneId != null && lotId == null) CalendarEventError.zoneWithoutLot,
    };
  }

  /// La entrada, o `ValidationFailure` con los motivos en `errors`.
  static Result<NewCalendarEvent> create({
    required CalendarEventType type,
    required String name,
    required DemandImpact impact,
    required DateTime startsAt,
    required DateTime endsAt,
    LotId? lotId,
    ZoneId? zoneId,
  }) {
    final errors = validate(
      name: name,
      startsAt: startsAt,
      endsAt: endsAt,
      lotId: lotId,
      zoneId: zoneId,
    );
    if (errors.isNotEmpty) {
      return Err(
        ValidationFailure('El evento no es válido.', {
          'event': [for (final error in errors) error.name],
        }),
      );
    }
    return Success(
      NewCalendarEvent._(
        type: type,
        name: name.trim(),
        impact: impact,
        startsAt: startsAt.toUtc(),
        endsAt: endsAt.toUtc(),
        lotId: lotId,
        zoneId: zoneId,
      ),
    );
  }

  final CalendarEventType type;
  final String name;
  final DemandImpact impact;
  final DateTime startsAt;
  final DateTime endsAt;
  final LotId? lotId;
  final ZoneId? zoneId;

  @override
  List<Object?> get props => [
    type,
    name,
    impact,
    startsAt,
    endsAt,
    lotId?.value,
    zoneId?.value,
  ];
}

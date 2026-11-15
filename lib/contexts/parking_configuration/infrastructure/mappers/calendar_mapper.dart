import 'package:quadrapp_mobile/contexts/parking_configuration/domain/entities/calendar_event.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/dto/calendar_event_dto.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/logging/logger.dart';
import 'package:quadrapp_mobile/core/network/parse_exception.dart';

/// DTO <-> entidades del calendario. Un valor desconocido del servidor no
/// rompe la pantalla:
/// - un `type` desconocido se trata como evento del campus;
/// - un `impact` desconocido, como medio (el valor por defecto de docs/06);
/// - una entrada cuyo fin no es posterior al inicio se omite.
/// Cada caso deja un aviso.
class CalendarMapper {
  const CalendarMapper(this._logger);

  final Logger _logger;

  List<CalendarEvent> toEvents(List<CalendarEventDto> dtos) => [
    for (final dto in dtos) ?_eventOrNull(dto),
  ];

  /// La respuesta de `POST /calendar-events`.
  CalendarEvent toEvent(CalendarEventDto dto) =>
      _eventOrNull(dto) ??
      (throw const ParseException('El evento creado no es válido.'));

  CalendarEvent? _eventOrNull(CalendarEventDto dto) {
    final startsAt = dto.startsAt.toUtc();
    final endsAt = dto.endsAt.toUtc();
    if (!endsAt.isAfter(startsAt)) {
      _logger.warning('Evento con fin anterior al inicio: se omite');
      return null;
    }
    return CalendarEvent(
      id: CalendarEventId(dto.id),
      type: parseType(dto.type),
      name: dto.name,
      impact: parseImpact(dto.impact),
      startsAt: startsAt,
      endsAt: endsAt,
      lotId: dto.lotId == null ? null : LotId(dto.lotId!),
      lotName: dto.lotName,
      zoneId: dto.zoneId == null ? null : ZoneId(dto.zoneId!),
      zoneName: dto.zoneName,
    );
  }

  NewCalendarEventDto toRequest(NewCalendarEvent event) => NewCalendarEventDto(
    type: typeToApi(event.type),
    name: event.name,
    impact: impactToApi(event.impact),
    startsAt: event.startsAt,
    endsAt: event.endsAt,
    lotId: event.lotId?.value,
    zoneId: event.zoneId?.value,
  );

  CalendarEventType parseType(String raw) {
    switch (raw.toUpperCase()) {
      case 'CLASSES':
        return CalendarEventType.classes;
      case 'EXAMS':
        return CalendarEventType.exams;
      case 'RECESS':
        return CalendarEventType.recess;
      case 'CAMPUS_EVENT':
        return CalendarEventType.campusEvent;
    }
    _logger.warning('Tipo de evento no reconocido "$raw": CAMPUS_EVENT');
    return CalendarEventType.campusEvent;
  }

  DemandImpact parseImpact(String raw) {
    switch (raw.toUpperCase()) {
      case 'LOW':
        return DemandImpact.low;
      case 'MEDIUM':
        return DemandImpact.medium;
      case 'HIGH':
        return DemandImpact.high;
    }
    _logger.warning('Impacto no reconocido "$raw": MEDIUM');
    return DemandImpact.medium;
  }

  String typeToApi(CalendarEventType type) => switch (type) {
    CalendarEventType.classes => 'CLASSES',
    CalendarEventType.exams => 'EXAMS',
    CalendarEventType.recess => 'RECESS',
    CalendarEventType.campusEvent => 'CAMPUS_EVENT',
  };

  String impactToApi(DemandImpact impact) => switch (impact) {
    DemandImpact.low => 'LOW',
    DemandImpact.medium => 'MEDIUM',
    DemandImpact.high => 'HIGH',
  };
}

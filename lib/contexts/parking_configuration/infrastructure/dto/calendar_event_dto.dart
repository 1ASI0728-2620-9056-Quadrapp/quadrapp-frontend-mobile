import 'package:json_annotation/json_annotation.dart';

part 'calendar_event_dto.g.dart';

/// Una entrada de `GET/POST /calendar-events` (docs/07).
@JsonSerializable()
class CalendarEventDto {
  const CalendarEventDto({
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

  factory CalendarEventDto.fromJson(Map<String, dynamic> json) =>
      _$CalendarEventDtoFromJson(json);

  final int id;

  /// `CLASSES`, `EXAMS`, `RECESS` o `CAMPUS_EVENT`.
  final String type;
  final String name;

  /// `LOW`, `MEDIUM` o `HIGH`.
  final String impact;
  final DateTime startsAt;
  final DateTime endsAt;
  final int? lotId;
  final String? lotName;
  final int? zoneId;
  final String? zoneName;

  Map<String, dynamic> toJson() => _$CalendarEventDtoToJson(this);
}

/// El cuerpo de `POST /calendar-events`.
@JsonSerializable(includeIfNull: false)
class NewCalendarEventDto {
  const NewCalendarEventDto({
    required this.type,
    required this.name,
    required this.impact,
    required this.startsAt,
    required this.endsAt,
    this.lotId,
    this.zoneId,
  });

  factory NewCalendarEventDto.fromJson(Map<String, dynamic> json) =>
      _$NewCalendarEventDtoFromJson(json);

  final String type;
  final String name;
  final String impact;
  final DateTime startsAt;
  final DateTime endsAt;
  final int? lotId;
  final int? zoneId;

  Map<String, dynamic> toJson() => _$NewCalendarEventDtoToJson(this);
}

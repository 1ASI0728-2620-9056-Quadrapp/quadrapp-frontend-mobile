// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calendar_event_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CalendarEventDto _$CalendarEventDtoFromJson(Map<String, dynamic> json) =>
    CalendarEventDto(
      id: (json['id'] as num).toInt(),
      type: json['type'] as String,
      name: json['name'] as String,
      impact: json['impact'] as String,
      startsAt: DateTime.parse(json['startsAt'] as String),
      endsAt: DateTime.parse(json['endsAt'] as String),
      lotId: (json['lotId'] as num?)?.toInt(),
      lotName: json['lotName'] as String?,
      zoneId: (json['zoneId'] as num?)?.toInt(),
      zoneName: json['zoneName'] as String?,
    );

Map<String, dynamic> _$CalendarEventDtoToJson(CalendarEventDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'name': instance.name,
      'impact': instance.impact,
      'startsAt': instance.startsAt.toIso8601String(),
      'endsAt': instance.endsAt.toIso8601String(),
      'lotId': instance.lotId,
      'lotName': instance.lotName,
      'zoneId': instance.zoneId,
      'zoneName': instance.zoneName,
    };

NewCalendarEventDto _$NewCalendarEventDtoFromJson(Map<String, dynamic> json) =>
    NewCalendarEventDto(
      type: json['type'] as String,
      name: json['name'] as String,
      impact: json['impact'] as String,
      startsAt: DateTime.parse(json['startsAt'] as String),
      endsAt: DateTime.parse(json['endsAt'] as String),
      lotId: (json['lotId'] as num?)?.toInt(),
      zoneId: (json['zoneId'] as num?)?.toInt(),
    );

Map<String, dynamic> _$NewCalendarEventDtoToJson(
  NewCalendarEventDto instance,
) => <String, dynamic>{
  'type': instance.type,
  'name': instance.name,
  'impact': instance.impact,
  'startsAt': instance.startsAt.toIso8601String(),
  'endsAt': instance.endsAt.toIso8601String(),
  'lotId': ?instance.lotId,
  'zoneId': ?instance.zoneId,
};

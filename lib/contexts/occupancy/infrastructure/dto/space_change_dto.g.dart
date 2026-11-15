// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'space_change_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SpaceChangeDto _$SpaceChangeDtoFromJson(Map<String, dynamic> json) =>
    SpaceChangeDto(
      eventId: json['eventId'] as String,
      spaceId: (json['spaceId'] as num).toInt(),
      status: json['status'] as String,
      at: DateTime.parse(json['at'] as String),
    );

Map<String, dynamic> _$SpaceChangeDtoToJson(SpaceChangeDto instance) =>
    <String, dynamic>{
      'eventId': instance.eventId,
      'spaceId': instance.spaceId,
      'status': instance.status,
      'at': instance.at.toIso8601String(),
    };

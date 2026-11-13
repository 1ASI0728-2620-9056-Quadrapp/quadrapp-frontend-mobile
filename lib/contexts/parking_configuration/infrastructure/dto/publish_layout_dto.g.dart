// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'publish_layout_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublishLayoutRequestDto _$PublishLayoutRequestDtoFromJson(
  Map<String, dynamic> json,
) => PublishLayoutRequestDto(
  baseVersion: (json['baseVersion'] as num).toInt(),
  newZones: (json['newZones'] as List<dynamic>)
      .map((e) => NewZoneDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  newSpaces: (json['newSpaces'] as List<dynamic>)
      .map((e) => PublishSpaceDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  updatedSpaces: (json['updatedSpaces'] as List<dynamic>)
      .map((e) => UpdatedSpaceDto.fromJson(e as Map<String, dynamic>))
      .toList(),
  disabledSpaceIds: (json['disabledSpaceIds'] as List<dynamic>)
      .map((e) => (e as num).toInt())
      .toList(),
);

Map<String, dynamic> _$PublishLayoutRequestDtoToJson(
  PublishLayoutRequestDto instance,
) => <String, dynamic>{
  'baseVersion': instance.baseVersion,
  'newZones': instance.newZones.map((e) => e.toJson()).toList(),
  'newSpaces': instance.newSpaces.map((e) => e.toJson()).toList(),
  'updatedSpaces': instance.updatedSpaces.map((e) => e.toJson()).toList(),
  'disabledSpaceIds': instance.disabledSpaceIds,
};

NewZoneDto _$NewZoneDtoFromJson(Map<String, dynamic> json) => NewZoneDto(
  key: json['key'] as String,
  name: json['name'] as String,
  levelName: json['levelName'] as String,
);

Map<String, dynamic> _$NewZoneDtoToJson(NewZoneDto instance) =>
    <String, dynamic>{
      'key': instance.key,
      'name': instance.name,
      'levelName': instance.levelName,
    };

PublishSpaceDto _$PublishSpaceDtoFromJson(Map<String, dynamic> json) =>
    PublishSpaceDto(
      label: json['label'] as String,
      type: json['type'] as String,
      active: json['active'] as bool,
      levelId: (json['levelId'] as num?)?.toInt(),
      zoneKey: json['zoneKey'] as String?,
    );

Map<String, dynamic> _$PublishSpaceDtoToJson(PublishSpaceDto instance) =>
    <String, dynamic>{
      'levelId': ?instance.levelId,
      'zoneKey': ?instance.zoneKey,
      'label': instance.label,
      'type': instance.type,
      'active': instance.active,
    };

UpdatedSpaceDto _$UpdatedSpaceDtoFromJson(Map<String, dynamic> json) =>
    UpdatedSpaceDto(
      spaceId: (json['spaceId'] as num).toInt(),
      label: json['label'] as String,
      type: json['type'] as String,
    );

Map<String, dynamic> _$UpdatedSpaceDtoToJson(UpdatedSpaceDto instance) =>
    <String, dynamic>{
      'spaceId': instance.spaceId,
      'label': instance.label,
      'type': instance.type,
    };

PublishLayoutResponseDto _$PublishLayoutResponseDtoFromJson(
  Map<String, dynamic> json,
) => PublishLayoutResponseDto(version: (json['version'] as num).toInt());

Map<String, dynamic> _$PublishLayoutResponseDtoToJson(
  PublishLayoutResponseDto instance,
) => <String, dynamic>{'version': instance.version};

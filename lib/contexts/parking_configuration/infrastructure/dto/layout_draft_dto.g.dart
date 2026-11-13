// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'layout_draft_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LayoutDraftDto _$LayoutDraftDtoFromJson(Map<String, dynamic> json) =>
    LayoutDraftDto(
      lotId: (json['lotId'] as num).toInt(),
      baseVersion: (json['baseVersion'] as num).toInt(),
      nextSeq: (json['nextSeq'] as num).toInt(),
      changes: (json['changes'] as List<dynamic>)
          .map((e) => LayoutChangeDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$LayoutDraftDtoToJson(LayoutDraftDto instance) =>
    <String, dynamic>{
      'lotId': instance.lotId,
      'baseVersion': instance.baseVersion,
      'nextSeq': instance.nextSeq,
      'changes': instance.changes.map((e) => e.toJson()).toList(),
    };

LayoutChangeDto _$LayoutChangeDtoFromJson(Map<String, dynamic> json) =>
    LayoutChangeDto(
      kind: json['kind'] as String,
      key: json['key'] as String?,
      name: json['name'] as String?,
      levelName: json['levelName'] as String?,
      spaces: (json['spaces'] as List<dynamic>?)
          ?.map((e) => NewSpaceDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      zoneKey: json['zoneKey'] as String?,
      levelKey: json['levelKey'] as String?,
      space: json['space'] == null
          ? null
          : NewSpaceDto.fromJson(json['space'] as Map<String, dynamic>),
      spaceKey: json['spaceKey'] as String?,
      label: json['label'] as String?,
      type: json['type'] as String?,
      enabled: json['enabled'] as bool?,
    );

Map<String, dynamic> _$LayoutChangeDtoToJson(LayoutChangeDto instance) =>
    <String, dynamic>{
      'kind': instance.kind,
      'key': ?instance.key,
      'name': ?instance.name,
      'levelName': ?instance.levelName,
      'spaces': ?instance.spaces?.map((e) => e.toJson()).toList(),
      'zoneKey': ?instance.zoneKey,
      'levelKey': ?instance.levelKey,
      'space': ?instance.space?.toJson(),
      'spaceKey': ?instance.spaceKey,
      'label': ?instance.label,
      'type': ?instance.type,
      'enabled': ?instance.enabled,
    };

NewSpaceDto _$NewSpaceDtoFromJson(Map<String, dynamic> json) => NewSpaceDto(
  key: json['key'] as String,
  label: json['label'] as String,
  type: json['type'] as String,
  enabled: json['enabled'] as bool,
);

Map<String, dynamic> _$NewSpaceDtoToJson(NewSpaceDto instance) =>
    <String, dynamic>{
      'key': instance.key,
      'label': instance.label,
      'type': instance.type,
      'enabled': instance.enabled,
    };

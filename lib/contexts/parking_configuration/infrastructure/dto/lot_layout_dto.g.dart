// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lot_layout_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LotLayoutDto _$LotLayoutDtoFromJson(Map<String, dynamic> json) => LotLayoutDto(
  version: (json['version'] as num).toInt(),
  zones:
      (json['zones'] as List<dynamic>?)
          ?.map((e) => ZoneDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$LotLayoutDtoToJson(LotLayoutDto instance) =>
    <String, dynamic>{
      'version': instance.version,
      'zones': instance.zones.map((e) => e.toJson()).toList(),
    };

ZoneDto _$ZoneDtoFromJson(Map<String, dynamic> json) => ZoneDto(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  description: json['description'] as String?,
  levels:
      (json['levels'] as List<dynamic>?)
          ?.map((e) => LevelDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$ZoneDtoToJson(ZoneDto instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'levels': instance.levels.map((e) => e.toJson()).toList(),
};

LevelDto _$LevelDtoFromJson(Map<String, dynamic> json) => LevelDto(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  spaces:
      (json['spaces'] as List<dynamic>?)
          ?.map((e) => SpaceDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$LevelDtoToJson(LevelDto instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'spaces': instance.spaces.map((e) => e.toJson()).toList(),
};

SpaceDto _$SpaceDtoFromJson(Map<String, dynamic> json) => SpaceDto(
  id: (json['id'] as num).toInt(),
  label: json['label'] as String,
  posX: (json['posX'] as num?)?.toDouble(),
  posY: (json['posY'] as num?)?.toDouble(),
);

Map<String, dynamic> _$SpaceDtoToJson(SpaceDto instance) => <String, dynamic>{
  'id': instance.id,
  'label': instance.label,
  'posX': instance.posX,
  'posY': instance.posY,
};

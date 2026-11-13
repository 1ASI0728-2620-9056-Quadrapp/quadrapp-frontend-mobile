import 'package:json_annotation/json_annotation.dart';

part 'publish_layout_dto.g.dart';

/// `POST /parking-lots/{lotId}/layout/publish` (docs/07, US17): el efecto
/// neto del borrador sobre la versión [baseVersion].
@JsonSerializable(explicitToJson: true)
class PublishLayoutRequestDto {
  const PublishLayoutRequestDto({
    required this.baseVersion,
    required this.newZones,
    required this.newSpaces,
    required this.updatedSpaces,
    required this.disabledSpaceIds,
  });

  factory PublishLayoutRequestDto.fromJson(Map<String, dynamic> json) =>
      _$PublishLayoutRequestDtoFromJson(json);

  final int baseVersion;
  final List<NewZoneDto> newZones;
  final List<PublishSpaceDto> newSpaces;
  final List<UpdatedSpaceDto> updatedSpaces;
  final List<int> disabledSpaceIds;

  Map<String, dynamic> toJson() => _$PublishLayoutRequestDtoToJson(this);
}

/// Una zona nueva con su único nivel; [key] la une con sus espacios.
@JsonSerializable()
class NewZoneDto {
  const NewZoneDto({
    required this.key,
    required this.name,
    required this.levelName,
  });

  factory NewZoneDto.fromJson(Map<String, dynamic> json) =>
      _$NewZoneDtoFromJson(json);

  final String key;
  final String name;
  final String levelName;

  Map<String, dynamic> toJson() => _$NewZoneDtoToJson(this);
}

/// Un espacio nuevo: en un nivel publicado ([levelId]) o en el nivel de una
/// zona nueva ([zoneKey]); exactamente uno de los dos.
@JsonSerializable(includeIfNull: false)
class PublishSpaceDto {
  const PublishSpaceDto({
    required this.label,
    required this.type,
    required this.active,
    this.levelId,
    this.zoneKey,
  });

  factory PublishSpaceDto.fromJson(Map<String, dynamic> json) =>
      _$PublishSpaceDtoFromJson(json);

  final int? levelId;
  final String? zoneKey;
  final String label;
  final String type;
  final bool active;

  Map<String, dynamic> toJson() => _$PublishSpaceDtoToJson(this);
}

@JsonSerializable()
class UpdatedSpaceDto {
  const UpdatedSpaceDto({
    required this.spaceId,
    required this.label,
    required this.type,
  });

  factory UpdatedSpaceDto.fromJson(Map<String, dynamic> json) =>
      _$UpdatedSpaceDtoFromJson(json);

  final int spaceId;
  final String label;
  final String type;

  Map<String, dynamic> toJson() => _$UpdatedSpaceDtoToJson(this);
}

/// 200 `{ version }`.
@JsonSerializable()
class PublishLayoutResponseDto {
  const PublishLayoutResponseDto({required this.version});

  factory PublishLayoutResponseDto.fromJson(Map<String, dynamic> json) =>
      _$PublishLayoutResponseDtoFromJson(json);

  final int version;

  Map<String, dynamic> toJson() => _$PublishLayoutResponseDtoToJson(this);
}

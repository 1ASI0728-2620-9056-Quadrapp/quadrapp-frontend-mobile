import 'package:json_annotation/json_annotation.dart';

part 'layout_draft_dto.g.dart';

/// El borrador guardado en el teléfono (no viaja al servidor): los cambios en
/// orden, para poder deshacerlos.
@JsonSerializable(explicitToJson: true)
class LayoutDraftDto {
  const LayoutDraftDto({
    required this.lotId,
    required this.baseVersion,
    required this.nextSeq,
    required this.changes,
  });

  factory LayoutDraftDto.fromJson(Map<String, dynamic> json) =>
      _$LayoutDraftDtoFromJson(json);

  final int lotId;
  final int baseVersion;
  final int nextSeq;
  final List<LayoutChangeDto> changes;

  Map<String, dynamic> toJson() => _$LayoutDraftDtoToJson(this);
}

/// Un cambio: `kind` es `ADD_ZONE`, `ADD_SPACE`, `EDIT_SPACE` o
/// `SET_ENABLED`, con los campos de su tipo.
@JsonSerializable(explicitToJson: true, includeIfNull: false)
class LayoutChangeDto {
  const LayoutChangeDto({
    required this.kind,
    this.key,
    this.name,
    this.levelName,
    this.spaces,
    this.zoneKey,
    this.levelKey,
    this.space,
    this.spaceKey,
    this.label,
    this.type,
    this.enabled,
  });

  factory LayoutChangeDto.fromJson(Map<String, dynamic> json) =>
      _$LayoutChangeDtoFromJson(json);

  final String kind;
  final String? key;
  final String? name;
  final String? levelName;
  final List<NewSpaceDto>? spaces;
  final String? zoneKey;
  final String? levelKey;
  final NewSpaceDto? space;
  final String? spaceKey;
  final String? label;
  final String? type;
  final bool? enabled;

  Map<String, dynamic> toJson() => _$LayoutChangeDtoToJson(this);
}

@JsonSerializable()
class NewSpaceDto {
  const NewSpaceDto({
    required this.key,
    required this.label,
    required this.type,
    required this.enabled,
  });

  factory NewSpaceDto.fromJson(Map<String, dynamic> json) =>
      _$NewSpaceDtoFromJson(json);

  final String key;
  final String label;
  final String type;
  final bool enabled;

  Map<String, dynamic> toJson() => _$NewSpaceDtoToJson(this);
}

import 'package:json_annotation/json_annotation.dart';

part 'lot_layout_dto.g.dart';

/// `GET /parking-lots/{lotId}/layout`: `{ version, zones[{ id, name,
/// description?, levels[{ id, name, spaces[{ id, label, posX, posY }] }] }] }`.
@JsonSerializable(explicitToJson: true)
class LotLayoutDto {
  const LotLayoutDto({required this.version, this.zones = const []});

  factory LotLayoutDto.fromJson(Map<String, dynamic> json) =>
      _$LotLayoutDtoFromJson(json);

  final int version;
  final List<ZoneDto> zones;

  Map<String, dynamic> toJson() => _$LotLayoutDtoToJson(this);
}

@JsonSerializable(explicitToJson: true)
class ZoneDto {
  const ZoneDto({
    required this.id,
    required this.name,
    this.description,
    this.levels = const [],
  });

  factory ZoneDto.fromJson(Map<String, dynamic> json) =>
      _$ZoneDtoFromJson(json);

  final int id;
  final String name;
  final String? description;
  final List<LevelDto> levels;

  Map<String, dynamic> toJson() => _$ZoneDtoToJson(this);
}

@JsonSerializable(explicitToJson: true)
class LevelDto {
  const LevelDto({
    required this.id,
    required this.name,
    this.spaces = const [],
  });

  factory LevelDto.fromJson(Map<String, dynamic> json) =>
      _$LevelDtoFromJson(json);

  final int id;
  final String name;
  final List<SpaceDto> spaces;

  Map<String, dynamic> toJson() => _$LevelDtoToJson(this);
}

@JsonSerializable()
class SpaceDto {
  const SpaceDto({
    required this.id,
    required this.label,
    this.posX,
    this.posY,
  });

  factory SpaceDto.fromJson(Map<String, dynamic> json) =>
      _$SpaceDtoFromJson(json);

  final int id;
  final String label;
  final double? posX;
  final double? posY;

  Map<String, dynamic> toJson() => _$SpaceDtoToJson(this);
}

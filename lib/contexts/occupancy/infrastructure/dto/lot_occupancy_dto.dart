import 'package:json_annotation/json_annotation.dart';

part 'lot_occupancy_dto.g.dart';

/// `GET /parking-lots/{lotId}/occupancy` y la sección `occupancy` de
/// `GET /mobile/home` (docs/07).
@JsonSerializable(explicitToJson: true)
class LotOccupancyDto {
  const LotOccupancyDto({
    required this.capacity,
    required this.free,
    required this.occupied,
    required this.unknown,
    required this.consolidatedAt,
    required this.serverTime,
    required this.staleAfterSeconds,
    this.stale = false,
    this.zones = const [],
    this.spaces = const [],
  });

  factory LotOccupancyDto.fromJson(Map<String, dynamic> json) =>
      _$LotOccupancyDtoFromJson(json);

  final int capacity;
  final int free;
  final int occupied;
  final int unknown;
  final DateTime consolidatedAt;
  final DateTime serverTime;
  final int staleAfterSeconds;
  final bool stale;
  final List<ZoneOccupancyDto> zones;
  final List<SpaceStateDto> spaces;

  Map<String, dynamic> toJson() => _$LotOccupancyDtoToJson(this);
}

@JsonSerializable()
class ZoneOccupancyDto {
  const ZoneOccupancyDto({
    required this.id,
    required this.free,
    required this.occupied,
    required this.unknown,
  });

  factory ZoneOccupancyDto.fromJson(Map<String, dynamic> json) =>
      _$ZoneOccupancyDtoFromJson(json);

  final int id;
  final int free;
  final int occupied;
  final int unknown;

  Map<String, dynamic> toJson() => _$ZoneOccupancyDtoToJson(this);
}

@JsonSerializable()
class SpaceStateDto {
  const SpaceStateDto({
    required this.id,
    required this.status,
    this.unknownReason,
  });

  factory SpaceStateDto.fromJson(Map<String, dynamic> json) =>
      _$SpaceStateDtoFromJson(json);

  final int id;

  /// `FREE`, `OCCUPIED` o `UNKNOWN` (se lee sin distinguir mayúsculas; un valor
  /// no reconocido se trata como `UNKNOWN`).
  final String status;
  final String? unknownReason;

  Map<String, dynamic> toJson() => _$SpaceStateDtoToJson(this);
}

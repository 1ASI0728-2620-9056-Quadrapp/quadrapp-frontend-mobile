import 'package:json_annotation/json_annotation.dart';

part 'shift_overview_dto.g.dart';

/// `GET /console/overview?lotId=` (docs/07, TS17).
@JsonSerializable(explicitToJson: true)
class ShiftOverviewDto {
  const ShiftOverviewDto({
    required this.lotId,
    required this.capacity,
    required this.free,
    required this.occupied,
    required this.unknown,
    required this.consolidatedAt,
    required this.serverTime,
    required this.staleAfterSeconds,
    this.stale = false,
    this.flow,
    this.saturation,
    this.unavailable = const [],
  });

  factory ShiftOverviewDto.fromJson(Map<String, dynamic> json) =>
      _$ShiftOverviewDtoFromJson(json);

  final int lotId;
  final int capacity;
  final int free;
  final int occupied;
  final int unknown;
  final ShiftFlowDto? flow;
  final ShiftSaturationDto? saturation;
  final DateTime consolidatedAt;
  final DateTime serverTime;
  final int staleAfterSeconds;
  final bool stale;
  final List<String> unavailable;

  Map<String, dynamic> toJson() => _$ShiftOverviewDtoToJson(this);
}

@JsonSerializable()
class ShiftFlowDto {
  const ShiftFlowDto({
    required this.entries,
    required this.exits,
    required this.windowMin,
  });

  factory ShiftFlowDto.fromJson(Map<String, dynamic> json) =>
      _$ShiftFlowDtoFromJson(json);

  final int entries;
  final int exits;
  final int windowMin;

  Map<String, dynamic> toJson() => _$ShiftFlowDtoToJson(this);
}

@JsonSerializable()
class ShiftSaturationDto {
  const ShiftSaturationDto({required this.expectedAt, required this.pct});

  factory ShiftSaturationDto.fromJson(Map<String, dynamic> json) =>
      _$ShiftSaturationDtoFromJson(json);

  final DateTime expectedAt;
  final double pct;

  Map<String, dynamic> toJson() => _$ShiftSaturationDtoToJson(this);
}

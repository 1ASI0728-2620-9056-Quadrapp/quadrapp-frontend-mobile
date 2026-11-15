import 'package:json_annotation/json_annotation.dart';

part 'accesses_overview_dto.g.dart';

/// `GET /console/accesses?lotId=` (docs/07, US19, US29).
@JsonSerializable(explicitToJson: true)
class AccessesOverviewDto {
  const AccessesOverviewDto({
    required this.lotId,
    required this.settings,
    required this.consolidatedAt,
    required this.serverTime,
    required this.staleAfterSeconds,
    this.stale = false,
    this.flow,
    this.accesses = const [],
    this.unavailable = const [],
  });

  factory AccessesOverviewDto.fromJson(Map<String, dynamic> json) =>
      _$AccessesOverviewDtoFromJson(json);

  final int lotId;
  final AccessSettingsDto settings;
  final AccessFlowDto? flow;
  final List<VehicleAccessDto> accesses;
  final DateTime consolidatedAt;
  final DateTime serverTime;
  final int staleAfterSeconds;
  final bool stale;
  final List<String> unavailable;

  Map<String, dynamic> toJson() => _$AccessesOverviewDtoToJson(this);
}

/// El bloque `settings`: la misma forma que `PATCH /parking-lots/{lotId}`.
@JsonSerializable()
class AccessSettingsDto {
  const AccessSettingsDto({
    required this.saturationThresholdPct,
    this.opensAt,
    this.closesAt,
  });

  factory AccessSettingsDto.fromJson(Map<String, dynamic> json) =>
      _$AccessSettingsDtoFromJson(json);

  final String? opensAt;
  final String? closesAt;
  final int saturationThresholdPct;

  Map<String, dynamic> toJson() => _$AccessSettingsDtoToJson(this);
}

@JsonSerializable(explicitToJson: true)
class AccessFlowDto {
  const AccessFlowDto({
    required this.entries,
    required this.exits,
    required this.windowMin,
    this.series = const [],
  });

  factory AccessFlowDto.fromJson(Map<String, dynamic> json) =>
      _$AccessFlowDtoFromJson(json);

  final int entries;
  final int exits;
  final int windowMin;
  final List<FlowMinuteDto> series;

  Map<String, dynamic> toJson() => _$AccessFlowDtoToJson(this);
}

@JsonSerializable()
class FlowMinuteDto {
  const FlowMinuteDto({
    required this.minuteStart,
    required this.entries,
    required this.exits,
  });

  factory FlowMinuteDto.fromJson(Map<String, dynamic> json) =>
      _$FlowMinuteDtoFromJson(json);

  final DateTime minuteStart;
  final int entries;
  final int exits;

  Map<String, dynamic> toJson() => _$FlowMinuteDtoToJson(this);
}

@JsonSerializable()
class VehicleAccessDto {
  const VehicleAccessDto({
    required this.id,
    required this.name,
    required this.type,
    required this.flowCountingEnabled,
    required this.status,
    this.entries,
    this.exits,
  });

  factory VehicleAccessDto.fromJson(Map<String, dynamic> json) =>
      _$VehicleAccessDtoFromJson(json);

  final int id;
  final String name;
  final String type;
  final bool flowCountingEnabled;
  final String status;
  final int? entries;
  final int? exits;

  Map<String, dynamic> toJson() => _$VehicleAccessDtoToJson(this);
}

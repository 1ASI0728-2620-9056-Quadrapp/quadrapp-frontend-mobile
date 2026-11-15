// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accesses_overview_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AccessesOverviewDto _$AccessesOverviewDtoFromJson(Map<String, dynamic> json) =>
    AccessesOverviewDto(
      lotId: (json['lotId'] as num).toInt(),
      settings: AccessSettingsDto.fromJson(
        json['settings'] as Map<String, dynamic>,
      ),
      consolidatedAt: DateTime.parse(json['consolidatedAt'] as String),
      serverTime: DateTime.parse(json['serverTime'] as String),
      staleAfterSeconds: (json['staleAfterSeconds'] as num).toInt(),
      stale: json['stale'] as bool? ?? false,
      flow: json['flow'] == null
          ? null
          : AccessFlowDto.fromJson(json['flow'] as Map<String, dynamic>),
      accesses:
          (json['accesses'] as List<dynamic>?)
              ?.map((e) => VehicleAccessDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      unavailable:
          (json['unavailable'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$AccessesOverviewDtoToJson(
  AccessesOverviewDto instance,
) => <String, dynamic>{
  'lotId': instance.lotId,
  'settings': instance.settings.toJson(),
  'flow': instance.flow?.toJson(),
  'accesses': instance.accesses.map((e) => e.toJson()).toList(),
  'consolidatedAt': instance.consolidatedAt.toIso8601String(),
  'serverTime': instance.serverTime.toIso8601String(),
  'staleAfterSeconds': instance.staleAfterSeconds,
  'stale': instance.stale,
  'unavailable': instance.unavailable,
};

AccessSettingsDto _$AccessSettingsDtoFromJson(Map<String, dynamic> json) =>
    AccessSettingsDto(
      saturationThresholdPct: (json['saturationThresholdPct'] as num).toInt(),
      opensAt: json['opensAt'] as String?,
      closesAt: json['closesAt'] as String?,
    );

Map<String, dynamic> _$AccessSettingsDtoToJson(AccessSettingsDto instance) =>
    <String, dynamic>{
      'opensAt': instance.opensAt,
      'closesAt': instance.closesAt,
      'saturationThresholdPct': instance.saturationThresholdPct,
    };

AccessFlowDto _$AccessFlowDtoFromJson(Map<String, dynamic> json) =>
    AccessFlowDto(
      entries: (json['entries'] as num).toInt(),
      exits: (json['exits'] as num).toInt(),
      windowMin: (json['windowMin'] as num).toInt(),
      series:
          (json['series'] as List<dynamic>?)
              ?.map((e) => FlowMinuteDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$AccessFlowDtoToJson(AccessFlowDto instance) =>
    <String, dynamic>{
      'entries': instance.entries,
      'exits': instance.exits,
      'windowMin': instance.windowMin,
      'series': instance.series.map((e) => e.toJson()).toList(),
    };

FlowMinuteDto _$FlowMinuteDtoFromJson(Map<String, dynamic> json) =>
    FlowMinuteDto(
      minuteStart: DateTime.parse(json['minuteStart'] as String),
      entries: (json['entries'] as num).toInt(),
      exits: (json['exits'] as num).toInt(),
    );

Map<String, dynamic> _$FlowMinuteDtoToJson(FlowMinuteDto instance) =>
    <String, dynamic>{
      'minuteStart': instance.minuteStart.toIso8601String(),
      'entries': instance.entries,
      'exits': instance.exits,
    };

VehicleAccessDto _$VehicleAccessDtoFromJson(Map<String, dynamic> json) =>
    VehicleAccessDto(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      type: json['type'] as String,
      flowCountingEnabled: json['flowCountingEnabled'] as bool,
      status: json['status'] as String,
      entries: (json['entries'] as num?)?.toInt(),
      exits: (json['exits'] as num?)?.toInt(),
    );

Map<String, dynamic> _$VehicleAccessDtoToJson(VehicleAccessDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': instance.type,
      'flowCountingEnabled': instance.flowCountingEnabled,
      'status': instance.status,
      'entries': instance.entries,
      'exits': instance.exits,
    };

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shift_overview_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ShiftOverviewDto _$ShiftOverviewDtoFromJson(Map<String, dynamic> json) =>
    ShiftOverviewDto(
      lotId: (json['lotId'] as num).toInt(),
      capacity: (json['capacity'] as num).toInt(),
      free: (json['free'] as num).toInt(),
      occupied: (json['occupied'] as num).toInt(),
      unknown: (json['unknown'] as num).toInt(),
      consolidatedAt: DateTime.parse(json['consolidatedAt'] as String),
      serverTime: DateTime.parse(json['serverTime'] as String),
      staleAfterSeconds: (json['staleAfterSeconds'] as num).toInt(),
      stale: json['stale'] as bool? ?? false,
      flow: json['flow'] == null
          ? null
          : ShiftFlowDto.fromJson(json['flow'] as Map<String, dynamic>),
      saturation: json['saturation'] == null
          ? null
          : ShiftSaturationDto.fromJson(
              json['saturation'] as Map<String, dynamic>,
            ),
      unavailable:
          (json['unavailable'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$ShiftOverviewDtoToJson(ShiftOverviewDto instance) =>
    <String, dynamic>{
      'lotId': instance.lotId,
      'capacity': instance.capacity,
      'free': instance.free,
      'occupied': instance.occupied,
      'unknown': instance.unknown,
      'flow': instance.flow?.toJson(),
      'saturation': instance.saturation?.toJson(),
      'consolidatedAt': instance.consolidatedAt.toIso8601String(),
      'serverTime': instance.serverTime.toIso8601String(),
      'staleAfterSeconds': instance.staleAfterSeconds,
      'stale': instance.stale,
      'unavailable': instance.unavailable,
    };

ShiftFlowDto _$ShiftFlowDtoFromJson(Map<String, dynamic> json) => ShiftFlowDto(
  entries: (json['entries'] as num).toInt(),
  exits: (json['exits'] as num).toInt(),
  windowMin: (json['windowMin'] as num).toInt(),
);

Map<String, dynamic> _$ShiftFlowDtoToJson(ShiftFlowDto instance) =>
    <String, dynamic>{
      'entries': instance.entries,
      'exits': instance.exits,
      'windowMin': instance.windowMin,
    };

ShiftSaturationDto _$ShiftSaturationDtoFromJson(Map<String, dynamic> json) =>
    ShiftSaturationDto(
      expectedAt: DateTime.parse(json['expectedAt'] as String),
      pct: (json['pct'] as num).toDouble(),
    );

Map<String, dynamic> _$ShiftSaturationDtoToJson(ShiftSaturationDto instance) =>
    <String, dynamic>{
      'expectedAt': instance.expectedAt.toIso8601String(),
      'pct': instance.pct,
    };

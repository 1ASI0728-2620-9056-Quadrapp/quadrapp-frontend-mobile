// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lot_occupancy_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LotOccupancyDto _$LotOccupancyDtoFromJson(Map<String, dynamic> json) =>
    LotOccupancyDto(
      capacity: (json['capacity'] as num).toInt(),
      free: (json['free'] as num).toInt(),
      occupied: (json['occupied'] as num).toInt(),
      unknown: (json['unknown'] as num).toInt(),
      consolidatedAt: DateTime.parse(json['consolidatedAt'] as String),
      serverTime: DateTime.parse(json['serverTime'] as String),
      staleAfterSeconds: (json['staleAfterSeconds'] as num).toInt(),
      stale: json['stale'] as bool? ?? false,
      zones:
          (json['zones'] as List<dynamic>?)
              ?.map((e) => ZoneOccupancyDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      spaces:
          (json['spaces'] as List<dynamic>?)
              ?.map((e) => SpaceStateDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$LotOccupancyDtoToJson(LotOccupancyDto instance) =>
    <String, dynamic>{
      'capacity': instance.capacity,
      'free': instance.free,
      'occupied': instance.occupied,
      'unknown': instance.unknown,
      'consolidatedAt': instance.consolidatedAt.toIso8601String(),
      'serverTime': instance.serverTime.toIso8601String(),
      'staleAfterSeconds': instance.staleAfterSeconds,
      'stale': instance.stale,
      'zones': instance.zones.map((e) => e.toJson()).toList(),
      'spaces': instance.spaces.map((e) => e.toJson()).toList(),
    };

ZoneOccupancyDto _$ZoneOccupancyDtoFromJson(Map<String, dynamic> json) =>
    ZoneOccupancyDto(
      id: (json['id'] as num).toInt(),
      free: (json['free'] as num).toInt(),
      occupied: (json['occupied'] as num).toInt(),
      unknown: (json['unknown'] as num).toInt(),
    );

Map<String, dynamic> _$ZoneOccupancyDtoToJson(ZoneOccupancyDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'free': instance.free,
      'occupied': instance.occupied,
      'unknown': instance.unknown,
    };

SpaceStateDto _$SpaceStateDtoFromJson(Map<String, dynamic> json) =>
    SpaceStateDto(
      id: (json['id'] as num).toInt(),
      status: json['status'] as String,
      unknownReason: json['unknownReason'] as String?,
    );

Map<String, dynamic> _$SpaceStateDtoToJson(SpaceStateDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': instance.status,
      'unknownReason': instance.unknownReason,
    };

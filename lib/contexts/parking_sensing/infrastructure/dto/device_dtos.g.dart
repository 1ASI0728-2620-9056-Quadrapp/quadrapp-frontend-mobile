// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceDto _$DeviceDtoFromJson(Map<String, dynamic> json) => DeviceDto(
  id: (json['id'] as num).toInt(),
  hardwareId: json['hardwareId'] as String,
  type: json['type'] as String,
  status: json['status'] as String,
  expectedReportIntervalSec: (json['expectedReportIntervalSec'] as num).toInt(),
  batteryPct: (json['batteryPct'] as num?)?.toInt(),
  lastSeenAt: json['lastSeenAt'] == null
      ? null
      : DateTime.parse(json['lastSeenAt'] as String),
  directional: json['directional'] as bool?,
  spaceLabel: json['spaceLabel'] as String?,
);

Map<String, dynamic> _$DeviceDtoToJson(DeviceDto instance) => <String, dynamic>{
  'id': instance.id,
  'hardwareId': instance.hardwareId,
  'type': instance.type,
  'status': instance.status,
  'expectedReportIntervalSec': instance.expectedReportIntervalSec,
  'batteryPct': instance.batteryPct,
  'lastSeenAt': instance.lastSeenAt?.toIso8601String(),
  'directional': instance.directional,
  'spaceLabel': instance.spaceLabel,
};

DeviceHealthDto _$DeviceHealthDtoFromJson(Map<String, dynamic> json) =>
    DeviceHealthDto(
      serverTime: DateTime.parse(json['serverTime'] as String),
      devices: (json['devices'] as List<dynamic>)
          .map((e) => DeviceDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$DeviceHealthDtoToJson(DeviceHealthDto instance) =>
    <String, dynamic>{
      'serverTime': instance.serverTime.toIso8601String(),
      'devices': instance.devices.map((e) => e.toJson()).toList(),
    };

RegisterDeviceRequestDto _$RegisterDeviceRequestDtoFromJson(
  Map<String, dynamic> json,
) => RegisterDeviceRequestDto(
  lotId: (json['lotId'] as num).toInt(),
  type: json['type'] as String,
  hardwareId: json['hardwareId'] as String,
  expectedReportIntervalSec: (json['expectedReportIntervalSec'] as num).toInt(),
  directional: json['directional'] as bool?,
);

Map<String, dynamic> _$RegisterDeviceRequestDtoToJson(
  RegisterDeviceRequestDto instance,
) => <String, dynamic>{
  'lotId': instance.lotId,
  'type': instance.type,
  'hardwareId': instance.hardwareId,
  'expectedReportIntervalSec': instance.expectedReportIntervalSec,
  'directional': ?instance.directional,
};

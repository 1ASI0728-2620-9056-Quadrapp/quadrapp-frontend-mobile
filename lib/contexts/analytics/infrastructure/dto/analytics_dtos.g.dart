// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OccupancyPointDto _$OccupancyPointDtoFromJson(Map<String, dynamic> json) =>
    OccupancyPointDto(
      at: DateTime.parse(json['at'] as String),
      occupancyPct: (json['occupancyPct'] as num).toDouble(),
    );

Map<String, dynamic> _$OccupancyPointDtoToJson(OccupancyPointDto instance) =>
    <String, dynamic>{
      'at': instance.at.toIso8601String(),
      'occupancyPct': instance.occupancyPct,
    };

OccupancyHistoryDto _$OccupancyHistoryDtoFromJson(Map<String, dynamic> json) =>
    OccupancyHistoryDto(
      serverTime: DateTime.parse(json['serverTime'] as String),
      granularity: json['granularity'] as String,
      points: (json['points'] as List<dynamic>)
          .map((e) => OccupancyPointDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$OccupancyHistoryDtoToJson(
  OccupancyHistoryDto instance,
) => <String, dynamic>{
  'serverTime': instance.serverTime.toIso8601String(),
  'granularity': instance.granularity,
  'points': instance.points.map((e) => e.toJson()).toList(),
};

PeakWindowDto _$PeakWindowDtoFromJson(Map<String, dynamic> json) =>
    PeakWindowDto(
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      avgOccupancyPct: (json['avgOccupancyPct'] as num).toDouble(),
    );

Map<String, dynamic> _$PeakWindowDtoToJson(PeakWindowDto instance) =>
    <String, dynamic>{
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'avgOccupancyPct': instance.avgOccupancyPct,
    };

PeakHoursDto _$PeakHoursDtoFromJson(Map<String, dynamic> json) => PeakHoursDto(
  sufficientData: json['sufficientData'] as bool,
  peaks:
      (json['peaks'] as List<dynamic>?)
          ?.map((e) => PeakWindowDto.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$PeakHoursDtoToJson(PeakHoursDto instance) =>
    <String, dynamic>{
      'sufficientData': instance.sufficientData,
      'peaks': instance.peaks.map((e) => e.toJson()).toList(),
    };

AccuracyResultDto _$AccuracyResultDtoFromJson(Map<String, dynamic> json) =>
    AccuracyResultDto(
      modelVersion: json['modelVersion'] as String,
      horizon: (json['horizon'] as num).toInt(),
      computable: json['computable'] as bool,
      maePoints: (json['maePoints'] as num?)?.toDouble(),
      withinMarginPct: (json['withinMarginPct'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$AccuracyResultDtoToJson(AccuracyResultDto instance) =>
    <String, dynamic>{
      'modelVersion': instance.modelVersion,
      'horizon': instance.horizon,
      'computable': instance.computable,
      'maePoints': instance.maePoints,
      'withinMarginPct': instance.withinMarginPct,
    };

ReportRequestDto _$ReportRequestDtoFromJson(Map<String, dynamic> json) =>
    ReportRequestDto(
      lotId: (json['lotId'] as num).toInt(),
      from: DateTime.parse(json['from'] as String),
      to: DateTime.parse(json['to'] as String),
      sections: (json['sections'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      format: json['format'] as String,
    );

Map<String, dynamic> _$ReportRequestDtoToJson(ReportRequestDto instance) =>
    <String, dynamic>{
      'lotId': instance.lotId,
      'from': instance.from.toIso8601String(),
      'to': instance.to.toIso8601String(),
      'sections': instance.sections,
      'format': instance.format,
    };

ReportDeliveryDto _$ReportDeliveryDtoFromJson(Map<String, dynamic> json) =>
    ReportDeliveryDto(sentTo: json['sentTo'] as String);

Map<String, dynamic> _$ReportDeliveryDtoToJson(ReportDeliveryDto instance) =>
    <String, dynamic>{'sentTo': instance.sentTo};

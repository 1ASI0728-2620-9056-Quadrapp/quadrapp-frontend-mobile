// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prediction_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ConfidenceDto _$ConfidenceDtoFromJson(Map<String, dynamic> json) =>
    ConfidenceDto(
      value: (json['value'] as num).toDouble(),
      level: json['level'] as String,
    );

Map<String, dynamic> _$ConfidenceDtoToJson(ConfidenceDto instance) =>
    <String, dynamic>{'value': instance.value, 'level': instance.level};

SaturationDto _$SaturationDtoFromJson(Map<String, dynamic> json) =>
    SaturationDto(
      expectedAt: DateTime.parse(json['expectedAt'] as String),
      pct: (json['pct'] as num).toDouble(),
    );

Map<String, dynamic> _$SaturationDtoToJson(SaturationDto instance) =>
    <String, dynamic>{
      'expectedAt': instance.expectedAt.toIso8601String(),
      'pct': instance.pct,
    };

ForecastDto _$ForecastDtoFromJson(Map<String, dynamic> json) => ForecastDto(
  horizon: (json['horizon'] as num).toInt(),
  expectedOccupancyPct: (json['expectedOccupancyPct'] as num).toDouble(),
  confidence: ConfidenceDto.fromJson(
    json['confidence'] as Map<String, dynamic>,
  ),
  modelVersion: json['modelVersion'] as String,
  method: json['method'] as String,
  generatedAt: DateTime.parse(json['generatedAt'] as String),
  validUntil: DateTime.parse(json['validUntil'] as String),
  serverTime: DateTime.parse(json['serverTime'] as String),
  saturation: json['saturation'] == null
      ? null
      : SaturationDto.fromJson(json['saturation'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ForecastDtoToJson(ForecastDto instance) =>
    <String, dynamic>{
      'horizon': instance.horizon,
      'expectedOccupancyPct': instance.expectedOccupancyPct,
      'confidence': instance.confidence.toJson(),
      'modelVersion': instance.modelVersion,
      'method': instance.method,
      'generatedAt': instance.generatedAt.toIso8601String(),
      'validUntil': instance.validUntil.toIso8601String(),
      'serverTime': instance.serverTime.toIso8601String(),
      'saturation': instance.saturation?.toJson(),
    };

ArrivalAdviceDto _$ArrivalAdviceDtoFromJson(Map<String, dynamic> json) =>
    ArrivalAdviceDto(
      etaMinutes: (json['etaMinutes'] as num).toInt(),
      probabilityOfSpace: (json['probabilityOfSpace'] as num).toDouble(),
      category: json['category'] as String,
      confidence: ConfidenceDto.fromJson(
        json['confidence'] as Map<String, dynamic>,
      ),
      horizonUsed: (json['horizonUsed'] as num).toInt(),
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      serverTime: DateTime.parse(json['serverTime'] as String),
    );

Map<String, dynamic> _$ArrivalAdviceDtoToJson(ArrivalAdviceDto instance) =>
    <String, dynamic>{
      'etaMinutes': instance.etaMinutes,
      'probabilityOfSpace': instance.probabilityOfSpace,
      'category': instance.category,
      'confidence': instance.confidence.toJson(),
      'horizonUsed': instance.horizonUsed,
      'generatedAt': instance.generatedAt.toIso8601String(),
      'serverTime': instance.serverTime.toIso8601String(),
    };

NextAvailabilityDto _$NextAvailabilityDtoFromJson(Map<String, dynamic> json) =>
    NextAvailabilityDto(
      available: json['available'] as bool,
      serverTime: DateTime.parse(json['serverTime'] as String),
      reason: json['reason'] as String?,
      minMinutes: (json['minMinutes'] as num?)?.toInt(),
      maxMinutes: (json['maxMinutes'] as num?)?.toInt(),
      confidence: json['confidence'] == null
          ? null
          : ConfidenceDto.fromJson(json['confidence'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$NextAvailabilityDtoToJson(
  NextAvailabilityDto instance,
) => <String, dynamic>{
  'available': instance.available,
  'reason': instance.reason,
  'minMinutes': instance.minMinutes,
  'maxMinutes': instance.maxMinutes,
  'confidence': instance.confidence?.toJson(),
  'serverTime': instance.serverTime.toIso8601String(),
};

ArrivalAdviceRequestDto _$ArrivalAdviceRequestDtoFromJson(
  Map<String, dynamic> json,
) => ArrivalAdviceRequestDto(
  lotId: (json['lotId'] as num).toInt(),
  etaMinutes: (json['etaMinutes'] as num).toInt(),
);

Map<String, dynamic> _$ArrivalAdviceRequestDtoToJson(
  ArrivalAdviceRequestDto instance,
) => <String, dynamic>{
  'lotId': instance.lotId,
  'etaMinutes': instance.etaMinutes,
};

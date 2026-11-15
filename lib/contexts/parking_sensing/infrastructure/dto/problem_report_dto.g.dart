// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'problem_report_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProblemReportRequestDto _$ProblemReportRequestDtoFromJson(
  Map<String, dynamic> json,
) => ProblemReportRequestDto(
  lotId: (json['lotId'] as num).toInt(),
  category: json['category'] as String,
  deviceId: (json['deviceId'] as num?)?.toInt(),
  detail: json['detail'] as String?,
);

Map<String, dynamic> _$ProblemReportRequestDtoToJson(
  ProblemReportRequestDto instance,
) => <String, dynamic>{
  'lotId': instance.lotId,
  'category': instance.category,
  'deviceId': ?instance.deviceId,
  'detail': ?instance.detail,
};

ProblemReceiptDto _$ProblemReceiptDtoFromJson(Map<String, dynamic> json) =>
    ProblemReceiptDto(
      id: (json['id'] as num).toInt(),
      detectedAt: DateTime.parse(json['detectedAt'] as String),
    );

Map<String, dynamic> _$ProblemReceiptDtoToJson(ProblemReceiptDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'detectedAt': instance.detectedAt.toIso8601String(),
    };

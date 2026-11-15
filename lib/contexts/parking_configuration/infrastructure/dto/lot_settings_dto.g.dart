// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lot_settings_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LotSettingsDto _$LotSettingsDtoFromJson(Map<String, dynamic> json) =>
    LotSettingsDto(
      saturationThresholdPct: (json['saturationThresholdPct'] as num).toInt(),
      opensAt: json['opensAt'] as String?,
      closesAt: json['closesAt'] as String?,
    );

Map<String, dynamic> _$LotSettingsDtoToJson(LotSettingsDto instance) =>
    <String, dynamic>{
      'opensAt': instance.opensAt,
      'closesAt': instance.closesAt,
      'saturationThresholdPct': instance.saturationThresholdPct,
    };

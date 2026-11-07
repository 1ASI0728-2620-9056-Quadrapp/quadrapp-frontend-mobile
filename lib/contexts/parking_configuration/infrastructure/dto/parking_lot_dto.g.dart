// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'parking_lot_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ParkingLotDto _$ParkingLotDtoFromJson(Map<String, dynamic> json) =>
    ParkingLotDto(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      layoutVersion: (json['layoutVersion'] as num).toInt(),
      staleAfterSeconds: (json['staleAfterSeconds'] as num).toInt(),
      saturationThresholdPct: (json['saturationThresholdPct'] as num?)?.toInt(),
      address: json['address'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$ParkingLotDtoToJson(ParkingLotDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'address': instance.address,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'layoutVersion': instance.layoutVersion,
      'staleAfterSeconds': instance.staleAfterSeconds,
      'saturationThresholdPct': instance.saturationThresholdPct,
    };

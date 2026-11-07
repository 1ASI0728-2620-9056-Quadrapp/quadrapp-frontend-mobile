import 'package:json_annotation/json_annotation.dart';

part 'parking_lot_dto.g.dart';

/// `GET /parking-lots` y `GET /parking-lots/{lotId}` (docs/07).
@JsonSerializable()
class ParkingLotDto {
  const ParkingLotDto({
    required this.id,
    required this.name,
    required this.layoutVersion,
    required this.staleAfterSeconds,
    this.saturationThresholdPct,
    this.address,
    this.latitude,
    this.longitude,
  });

  factory ParkingLotDto.fromJson(Map<String, dynamic> json) =>
      _$ParkingLotDtoFromJson(json);

  final int id;
  final String name;
  final String? address;
  final double? latitude;
  final double? longitude;
  final int layoutVersion;
  final int staleAfterSeconds;

  /// `saturation_threshold_pct` de docs/06; si falta, el mapper usa el valor
  /// por defecto del dominio.
  final int? saturationThresholdPct;

  Map<String, dynamic> toJson() => _$ParkingLotDtoToJson(this);
}

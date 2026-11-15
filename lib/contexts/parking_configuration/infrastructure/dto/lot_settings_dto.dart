import 'package:json_annotation/json_annotation.dart';

part 'lot_settings_dto.g.dart';

/// La configuración propia de un estacionamiento (docs/07): el cuerpo y la
/// respuesta de `PATCH /parking-lots/{lotId}` y el bloque `settings` de
/// `GET /console/accesses`. Las horas van como `HH:mm` (hora de Lima).
@JsonSerializable(includeIfNull: true)
class LotSettingsDto {
  const LotSettingsDto({
    required this.saturationThresholdPct,
    this.opensAt,
    this.closesAt,
  });

  factory LotSettingsDto.fromJson(Map<String, dynamic> json) =>
      _$LotSettingsDtoFromJson(json);

  final String? opensAt;
  final String? closesAt;
  final int saturationThresholdPct;

  Map<String, dynamic> toJson() => _$LotSettingsDtoToJson(this);
}

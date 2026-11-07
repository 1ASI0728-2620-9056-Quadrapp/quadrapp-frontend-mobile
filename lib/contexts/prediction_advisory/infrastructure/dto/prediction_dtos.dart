import 'package:json_annotation/json_annotation.dart';

part 'prediction_dtos.g.dart';

/// `confidence`: `{ value, level }` (docs/07, formas comunes).
@JsonSerializable()
class ConfidenceDto {
  const ConfidenceDto({required this.value, required this.level});

  factory ConfidenceDto.fromJson(Map<String, dynamic> json) =>
      _$ConfidenceDtoFromJson(json);

  final double value;

  /// `HIGH`, `MEDIUM` o `LOW`; un valor no reconocido se trata como `LOW`.
  final String level;

  Map<String, dynamic> toJson() => _$ConfidenceDtoToJson(this);
}

/// `saturation`: `{ expectedAt, pct }`.
@JsonSerializable()
class SaturationDto {
  const SaturationDto({required this.expectedAt, required this.pct});

  factory SaturationDto.fromJson(Map<String, dynamic> json) =>
      _$SaturationDtoFromJson(json);

  final DateTime expectedAt;
  final double pct;

  Map<String, dynamic> toJson() => _$SaturationDtoToJson(this);
}

/// `GET /forecasts` y cada elemento de `forecasts` del BFF.
@JsonSerializable(explicitToJson: true)
class ForecastDto {
  const ForecastDto({
    required this.horizon,
    required this.expectedOccupancyPct,
    required this.confidence,
    required this.modelVersion,
    required this.method,
    required this.generatedAt,
    required this.validUntil,
    required this.serverTime,
    this.saturation,
  });

  factory ForecastDto.fromJson(Map<String, dynamic> json) =>
      _$ForecastDtoFromJson(json);

  final int horizon;
  final double expectedOccupancyPct;
  final ConfidenceDto confidence;
  final String modelVersion;

  /// `PRIMARY_MODEL` o `FALLBACK`; un valor no reconocido se trata como
  /// `FALLBACK`.
  final String method;
  final DateTime generatedAt;
  final DateTime validUntil;
  final DateTime serverTime;
  final SaturationDto? saturation;

  Map<String, dynamic> toJson() => _$ForecastDtoToJson(this);
}

/// `POST /arrival-advices` y la sección `advice` del BFF.
@JsonSerializable(explicitToJson: true)
class ArrivalAdviceDto {
  const ArrivalAdviceDto({
    required this.etaMinutes,
    required this.probabilityOfSpace,
    required this.category,
    required this.confidence,
    required this.horizonUsed,
    required this.generatedAt,
    required this.serverTime,
  });

  factory ArrivalAdviceDto.fromJson(Map<String, dynamic> json) =>
      _$ArrivalAdviceDtoFromJson(json);

  final int etaMinutes;
  final double probabilityOfSpace;

  /// `HIGH`, `LIMITED` o `LOW`; un valor no reconocido deja la asesoría sin
  /// categoría (no disponible).
  final String category;
  final ConfidenceDto confidence;
  final int horizonUsed;
  final DateTime generatedAt;
  final DateTime serverTime;

  Map<String, dynamic> toJson() => _$ArrivalAdviceDtoToJson(this);
}

/// `GET /forecasts/{lotId}/next-availability` y `nextAvailability` del BFF.
@JsonSerializable(explicitToJson: true)
class NextAvailabilityDto {
  const NextAvailabilityDto({
    required this.available,
    required this.serverTime,
    this.reason,
    this.minMinutes,
    this.maxMinutes,
    this.confidence,
  });

  factory NextAvailabilityDto.fromJson(Map<String, dynamic> json) =>
      _$NextAvailabilityDtoFromJson(json);

  /// `true` = hay una estimación (no "hay espacios libres").
  final bool available;

  /// `NO_EXITS` o `HAS_FREE_SPACES`, solo si [available] es `false`.
  final String? reason;
  final int? minMinutes;
  final int? maxMinutes;
  final ConfidenceDto? confidence;
  final DateTime serverTime;

  Map<String, dynamic> toJson() => _$NextAvailabilityDtoToJson(this);
}

/// El cuerpo de `POST /arrival-advices`: **únicamente** `lotId` y
/// `etaMinutes` (TS08 esc. 3). No tiene ningún otro campo, a propósito: una
/// prueba serializa este objeto y falla si aparece cualquier otro.
@JsonSerializable()
class ArrivalAdviceRequestDto {
  const ArrivalAdviceRequestDto({
    required this.lotId,
    required this.etaMinutes,
  });

  factory ArrivalAdviceRequestDto.fromJson(Map<String, dynamic> json) =>
      _$ArrivalAdviceRequestDtoFromJson(json);

  final int lotId;
  final int etaMinutes;

  Map<String, dynamic> toJson() => _$ArrivalAdviceRequestDtoToJson(this);
}

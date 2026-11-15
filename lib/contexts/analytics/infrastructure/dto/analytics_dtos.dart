import 'package:json_annotation/json_annotation.dart';

part 'analytics_dtos.g.dart';

/// Un intervalo de `GET /analytics/occupancy` (docs/07).
@JsonSerializable()
class OccupancyPointDto {
  const OccupancyPointDto({required this.at, required this.occupancyPct});

  factory OccupancyPointDto.fromJson(Map<String, dynamic> json) =>
      _$OccupancyPointDtoFromJson(json);

  /// Inicio del intervalo (UTC).
  final DateTime at;
  final double occupancyPct;

  Map<String, dynamic> toJson() => _$OccupancyPointDtoToJson(this);
}

/// `GET /analytics/occupancy?lotId=&from=&to=&zoneId=&granularity=`.
@JsonSerializable(explicitToJson: true)
class OccupancyHistoryDto {
  const OccupancyHistoryDto({
    required this.serverTime,
    required this.granularity,
    required this.points,
  });

  factory OccupancyHistoryDto.fromJson(Map<String, dynamic> json) =>
      _$OccupancyHistoryDtoFromJson(json);

  final DateTime serverTime;

  /// `HOUR` o `DAY`.
  final String granularity;
  final List<OccupancyPointDto> points;

  Map<String, dynamic> toJson() => _$OccupancyHistoryDtoToJson(this);
}

/// Una franja de `GET /analytics/peaks`; las horas, `HH:mm` en
/// America/Lima.
@JsonSerializable()
class PeakWindowDto {
  const PeakWindowDto({
    required this.startTime,
    required this.endTime,
    required this.avgOccupancyPct,
  });

  factory PeakWindowDto.fromJson(Map<String, dynamic> json) =>
      _$PeakWindowDtoFromJson(json);

  final String startTime;
  final String endTime;
  final double avgOccupancyPct;

  Map<String, dynamic> toJson() => _$PeakWindowDtoToJson(this);
}

/// `GET /analytics/peaks?lotId=&from=&to=`.
@JsonSerializable(explicitToJson: true)
class PeakHoursDto {
  const PeakHoursDto({required this.sufficientData, this.peaks = const []});

  factory PeakHoursDto.fromJson(Map<String, dynamic> json) =>
      _$PeakHoursDtoFromJson(json);

  final bool sufficientData;
  final List<PeakWindowDto> peaks;

  Map<String, dynamic> toJson() => _$PeakHoursDtoToJson(this);
}

/// Cada elemento de `GET /analytics/accuracy?lotId=&from=&to=`.
@JsonSerializable()
class AccuracyResultDto {
  const AccuracyResultDto({
    required this.modelVersion,
    required this.horizon,
    required this.computable,
    this.maePoints,
    this.withinMarginPct,
  });

  factory AccuracyResultDto.fromJson(Map<String, dynamic> json) =>
      _$AccuracyResultDtoFromJson(json);

  final String modelVersion;
  final int horizon;
  final bool computable;
  final double? maePoints;
  final double? withinMarginPct;

  Map<String, dynamic> toJson() => _$AccuracyResultDtoToJson(this);
}

/// El cuerpo de `POST /analytics/reports`.
@JsonSerializable()
class ReportRequestDto {
  const ReportRequestDto({
    required this.lotId,
    required this.from,
    required this.to,
    required this.sections,
    required this.format,
  });

  factory ReportRequestDto.fromJson(Map<String, dynamic> json) =>
      _$ReportRequestDtoFromJson(json);

  final int lotId;
  final DateTime from;
  final DateTime to;

  /// `OCCUPANCY`, `ACCURACY` y `ALERTS`.
  final List<String> sections;

  /// `PDF` o `CSV`.
  final String format;

  Map<String, dynamic> toJson() => _$ReportRequestDtoToJson(this);
}

/// La respuesta 202 de `POST /analytics/reports`.
@JsonSerializable()
class ReportDeliveryDto {
  const ReportDeliveryDto({required this.sentTo});

  factory ReportDeliveryDto.fromJson(Map<String, dynamic> json) =>
      _$ReportDeliveryDtoFromJson(json);

  /// El correo de destino, enmascarado.
  final String sentTo;

  Map<String, dynamic> toJson() => _$ReportDeliveryDtoToJson(this);
}

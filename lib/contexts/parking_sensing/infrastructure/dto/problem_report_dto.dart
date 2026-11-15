import 'package:json_annotation/json_annotation.dart';

part 'problem_report_dto.g.dart';

/// El cuerpo de `POST /device-incidents` (docs/07).
@JsonSerializable(includeIfNull: false)
class ProblemReportRequestDto {
  const ProblemReportRequestDto({
    required this.lotId,
    required this.category,
    this.deviceId,
    this.detail,
  });

  factory ProblemReportRequestDto.fromJson(Map<String, dynamic> json) =>
      _$ProblemReportRequestDtoFromJson(json);

  final int lotId;

  /// `NO_COMMUNICATION`, `WRONG_DATA`, `LOW_BATTERY` u `OTHER`.
  final String category;
  final int? deviceId;
  final String? detail;

  Map<String, dynamic> toJson() => _$ProblemReportRequestDtoToJson(this);
}

/// La respuesta 201 de `POST /device-incidents`.
@JsonSerializable()
class ProblemReceiptDto {
  const ProblemReceiptDto({required this.id, required this.detectedAt});

  factory ProblemReceiptDto.fromJson(Map<String, dynamic> json) =>
      _$ProblemReceiptDtoFromJson(json);

  final int id;
  final DateTime detectedAt;

  Map<String, dynamic> toJson() => _$ProblemReceiptDtoToJson(this);
}

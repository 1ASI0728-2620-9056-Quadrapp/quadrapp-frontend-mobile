import 'package:json_annotation/json_annotation.dart';

part 'device_dtos.g.dart';

/// Un dispositivo: cada elemento de `GET /devices/health` y la respuesta de
/// `POST /devices` (docs/07).
@JsonSerializable()
class DeviceDto {
  const DeviceDto({
    required this.id,
    required this.hardwareId,
    required this.type,
    required this.status,
    required this.expectedReportIntervalSec,
    this.batteryPct,
    this.lastSeenAt,
    this.directional,
    this.spaceLabel,
  });

  factory DeviceDto.fromJson(Map<String, dynamic> json) =>
      _$DeviceDtoFromJson(json);

  final int id;
  final String hardwareId;

  /// `SPACE_SENSOR`, `PASS_SENSOR` o `GATEWAY`.
  final String type;

  /// `OPERATIONAL`, `UNREACHABLE`, `LOW_BATTERY` o `DECOMMISSIONED`.
  final String status;
  final int expectedReportIntervalSec;
  final int? batteryPct;
  final DateTime? lastSeenAt;
  final bool? directional;
  final String? spaceLabel;

  Map<String, dynamic> toJson() => _$DeviceDtoToJson(this);
}

/// `GET /devices/health?lotId=`.
@JsonSerializable(explicitToJson: true)
class DeviceHealthDto {
  const DeviceHealthDto({required this.serverTime, required this.devices});

  factory DeviceHealthDto.fromJson(Map<String, dynamic> json) =>
      _$DeviceHealthDtoFromJson(json);

  final DateTime serverTime;
  final List<DeviceDto> devices;

  Map<String, dynamic> toJson() => _$DeviceHealthDtoToJson(this);
}

/// El cuerpo de `POST /devices`. `directional` solo se envía con
/// `PASS_SENSOR`.
@JsonSerializable(includeIfNull: false)
class RegisterDeviceRequestDto {
  const RegisterDeviceRequestDto({
    required this.lotId,
    required this.type,
    required this.hardwareId,
    required this.expectedReportIntervalSec,
    this.directional,
  });

  factory RegisterDeviceRequestDto.fromJson(Map<String, dynamic> json) =>
      _$RegisterDeviceRequestDtoFromJson(json);

  final int lotId;
  final String type;
  final String hardwareId;
  final int expectedReportIntervalSec;
  final bool? directional;

  Map<String, dynamic> toJson() => _$RegisterDeviceRequestDtoToJson(this);
}

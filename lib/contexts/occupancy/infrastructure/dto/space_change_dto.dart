import 'package:json_annotation/json_annotation.dart';

part 'space_change_dto.g.dart';

/// Mensaje del WebSocket `/ws/parking-lots/{lotId}`:
/// `{ eventId, spaceId, status, at }` (docs/07, TS09).
@JsonSerializable()
class SpaceChangeDto {
  const SpaceChangeDto({
    required this.eventId,
    required this.spaceId,
    required this.status,
    required this.at,
  });

  factory SpaceChangeDto.fromJson(Map<String, dynamic> json) =>
      _$SpaceChangeDtoFromJson(json);

  final String eventId;
  final int spaceId;
  final String status;
  final DateTime at;

  Map<String, dynamic> toJson() => _$SpaceChangeDtoToJson(this);
}

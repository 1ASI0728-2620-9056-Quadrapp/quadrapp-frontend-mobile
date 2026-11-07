import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/value_objects/space_status.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

/// Estado actual de un espacio.
class SpaceState extends Equatable {
  const SpaceState({
    required this.id,
    required this.status,
    this.unknownReason,
  });

  final SpaceId id;
  final SpaceStatus status;

  /// Solo tiene sentido cuando [status] es `unknown`.
  final UnknownReason? unknownReason;

  @override
  List<Object?> get props => [id.value, status, unknownReason];
}

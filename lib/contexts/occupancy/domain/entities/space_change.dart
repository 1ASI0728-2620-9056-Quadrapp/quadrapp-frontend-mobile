import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/value_objects/space_status.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

/// Cambio de estado de un espacio, recibido en tiempo real (US07, TS09).
class SpaceChange extends Equatable {
  const SpaceChange({
    required this.eventId,
    required this.spaceId,
    required this.status,
    required this.at,
  });

  /// Identificador del evento (idempotencia, TS06).
  final String eventId;
  final SpaceId spaceId;
  final SpaceStatus status;

  /// Momento del cambio según el servidor (UTC).
  final DateTime at;

  @override
  List<Object?> get props => [eventId, spaceId.value, status, at];
}

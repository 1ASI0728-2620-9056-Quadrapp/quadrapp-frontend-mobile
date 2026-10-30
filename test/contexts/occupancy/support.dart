import 'package:quadrapp_mobile/contexts/occupancy/domain/entities/lot_occupancy.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/entities/space_state.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/entities/zone_occupancy.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/value_objects/freshness.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/value_objects/space_status.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

/// Momento de referencia de las pruebas (UTC).
final DateTime t0 = DateTime.utc(2026, 9, 28, 13, 41, 20);

SpaceState space(int id, SpaceStatus status, [UnknownReason? reason]) =>
    SpaceState(id: SpaceId(id), status: status, unknownReason: reason);

/// Ocupación con 4 espacios: 1 libre, 2 ocupados, 1 desconocido.
LotOccupancy sampleOccupancy({
  DateTime? consolidatedAt,
  Duration staleAfter = const Duration(seconds: 180),
  Duration? receivedAt = Duration.zero,
}) {
  final at = consolidatedAt ?? t0;
  return LotOccupancy(
    lotId: const LotId(1),
    capacity: 4,
    free: 1,
    occupied: 2,
    unknown: 1,
    freshness: Freshness(
      consolidatedAt: at,
      serverTime: at.add(const Duration(seconds: 40)),
      staleAfter: staleAfter,
      receivedAt: receivedAt,
    ),
    zones: const [
      ZoneOccupancy(zoneId: ZoneId(10), free: 1, occupied: 1, unknown: 0),
      ZoneOccupancy(zoneId: ZoneId(11), free: 0, occupied: 1, unknown: 1),
    ],
    spaces: [
      space(1, SpaceStatus.free),
      space(2, SpaceStatus.occupied),
      space(3, SpaceStatus.occupied),
      space(4, SpaceStatus.unknown, UnknownReason.lowBattery),
    ],
  );
}

/// Respuesta de `GET /parking-lots/{lotId}/occupancy` con el formato de
/// docs/07.
Map<String, dynamic> occupancyJson({
  String status = 'FREE',
  bool withZonesAndSpaces = true,
}) => {
  'capacity': 4,
  'free': 1,
  'occupied': 2,
  'unknown': 1,
  'consolidatedAt': '2026-09-28T13:41:20Z',
  'serverTime': '2026-09-28T13:42:00Z',
  'staleAfterSeconds': 180,
  'stale': false,
  if (withZonesAndSpaces) ...{
    'zones': [
      {'id': 10, 'free': 1, 'occupied': 1, 'unknown': 0},
      {'id': 11, 'free': 0, 'occupied': 1, 'unknown': 1},
    ],
    'spaces': [
      {'id': 1, 'status': status},
      {'id': 2, 'status': 'OCCUPIED'},
      {'id': 3, 'status': 'OCCUPIED'},
      {'id': 4, 'status': 'UNKNOWN', 'unknownReason': 'LOW_BATTERY'},
    ],
  },
};

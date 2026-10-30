import 'package:quadrapp_mobile/app/mocks/mock_world.dart';

/// Ocupación de [lot] con el formato exacto de docs/07 (`GET
/// /parking-lots/{lotId}/occupancy`). Con [detailed] `false` es la sección
/// `occupancy` de `GET /mobile/home` (sin zonas ni espacios).
Map<String, Object?> mockOccupancyJson(
  MockWorld world,
  MockLot lot, {
  bool detailed = true,
}) {
  final now = world.clock.now();
  final age = now.difference(lot.consolidatedAt);
  return {
    'capacity': lot.capacity,
    'free': lot.count('FREE'),
    'occupied': lot.count('OCCUPIED'),
    'unknown': lot.count('UNKNOWN'),
    'consolidatedAt': lot.consolidatedAt.toUtc().toIso8601String(),
    'serverTime': now.toUtc().toIso8601String(),
    'staleAfterSeconds': lot.staleAfterSeconds,
    'stale': age > Duration(seconds: lot.staleAfterSeconds),
    if (detailed) ...{
      'zones': [
        for (final zone in lot.zones)
          {
            'id': zone.id,
            'free': zone.spaces.where((s) => s.status == 'FREE').length,
            'occupied': zone.spaces.where((s) => s.status == 'OCCUPIED').length,
            'unknown': zone.spaces.where((s) => s.status == 'UNKNOWN').length,
          },
      ],
      'spaces': [
        for (final space in lot.spaces)
          {
            'id': space.id,
            'status': space.status,
            'unknownReason': ?space.unknownReason,
          },
      ],
    },
  };
}

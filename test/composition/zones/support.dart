import 'package:quadrapp_mobile/composition/zones/zones_state.dart';
import 'package:quadrapp_mobile/contexts/occupancy/occupancy.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

/// Momento de referencia de las pruebas (UTC); coincide con la hora del
/// `FakeClock` por defecto.
final DateTime t0 = DateTime.utc(2026, 9, 28, 13, 42);

ParkingLot lot({
  int id = 1,
  int layoutVersion = 4,
  int saturationThresholdPct = 90,
}) => ParkingLot(
  id: LotId(id),
  name: 'Sede $id',
  layoutVersion: layoutVersion,
  staleAfter: const Duration(seconds: 180),
  saturationThresholdPct: saturationThresholdPct,
);

Space _space(int id, String label, double x, double y) =>
    Space(id: SpaceId(id), label: label, posX: x, posY: y);

/// Dos pabellones: A («Edificios A–C») con dos niveles y B con uno solo. Ocho
/// espacios, todos con posición.
LotLayout layout({int lotId = 1, bool withPositions = true}) {
  Space s(int id, String label, double x, double y) => withPositions
      ? _space(id, label, x, y)
      : Space(id: SpaceId(id), label: label);
  return LotLayout(
    lotId: LotId(lotId),
    version: 4,
    zones: [
      Zone(
        id: const ZoneId(11),
        name: 'Pabellón A',
        description: 'Edificios A–C',
        levels: [
          Level(
            id: const LevelId(111),
            name: 'Sótano 2',
            spaces: [
              s(1, 'A-01', 0, 0),
              s(2, 'A-02', 1, 0),
              s(3, 'A-03', 0, 1),
              s(4, 'A-04', 1, 1),
            ],
          ),
          Level(
            id: const LevelId(112),
            name: 'Sótano 1',
            spaces: [s(5, 'A-05', 0, 0), s(6, 'A-06', 1, 0)],
          ),
        ],
      ),
      Zone(
        id: const ZoneId(12),
        name: 'Pabellón B',
        levels: [
          Level(
            id: const LevelId(121),
            name: 'Piso 1',
            spaces: [s(7, 'B-01', 0, 0), s(8, 'B-02', 1, 0)],
          ),
        ],
      ),
    ],
  );
}

SpaceState state(int id, SpaceStatus status, [UnknownReason? reason]) =>
    SpaceState(id: SpaceId(id), status: status, unknownReason: reason);

/// Ocupación de [layout]: libres 1, 5 y 6; sin datos el 3 (sin señal); el
/// resto ocupado. Pabellón A: 3 libres, 2 ocupados y 1 sin datos; pabellón B:
/// lleno.
LotOccupancy occupancy({
  int lotId = 1,
  Duration age = const Duration(seconds: 20),
  OccupancySource source = OccupancySource.network,
  List<SpaceState>? spaces,
  Duration staleAfter = const Duration(seconds: 180),
}) {
  final states =
      spaces ??
      [
        state(1, SpaceStatus.free),
        state(2, SpaceStatus.occupied),
        state(3, SpaceStatus.unknown, UnknownReason.noHeartbeat),
        state(4, SpaceStatus.occupied),
        state(5, SpaceStatus.free),
        state(6, SpaceStatus.free),
        state(7, SpaceStatus.occupied),
        state(8, SpaceStatus.occupied),
      ];
  int count(SpaceStatus status) =>
      states.where((s) => s.status == status).length;
  final consolidated = t0.subtract(age);
  return LotOccupancy(
    lotId: LotId(lotId),
    capacity: states.length,
    free: count(SpaceStatus.free),
    occupied: count(SpaceStatus.occupied),
    unknown: count(SpaceStatus.unknown),
    freshness: Freshness(
      consolidatedAt: consolidated,
      serverTime: t0,
      staleAfter: staleAfter,
      receivedAt: Duration.zero,
    ),
    spaces: states,
    source: source,
  );
}

/// Los conteos de [occupancy] por pabellón y nivel de [layout], como los
/// calcula el cubit.
ZonesOverview overview({
  ParkingLot? parkingLot,
  LotLayout? lotLayout,
  LotOccupancy? lotOccupancy,
  RealtimeLink? link,
}) {
  final resolvedLayout = lotLayout ?? layout();
  final resolvedOccupancy = lotOccupancy ?? occupancy();
  return ZonesOverview(
    lot: parkingLot ?? lot(),
    layout: resolvedLayout,
    occupancy: resolvedOccupancy,
    zoneCounts: {
      for (final z in const GetZoneSummary()(
        GetZoneSummaryParams(
          occupancy: resolvedOccupancy,
          membership: resolvedLayout.membership,
        ),
      ))
        z.zoneId: z,
    },
    levelCounts: {
      for (final l in const GetLevelSummary()(
        GetLevelSummaryParams(
          occupancy: resolvedOccupancy,
          membership: resolvedLayout.levelMembership,
        ),
      ))
        l.levelId: l,
    },
    link: link,
  );
}

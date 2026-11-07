import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/entities/level_occupancy.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/entities/space_state.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/entities/zone_occupancy.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/value_objects/space_status.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

/// Conteos de libres, ocupados y desconocidos.
class OccupancyCounts extends Equatable {
  const OccupancyCounts({
    required this.free,
    required this.occupied,
    required this.unknown,
  });

  final int free;
  final int occupied;
  final int unknown;

  int get total => free + occupied + unknown;

  @override
  List<Object?> get props => [free, occupied, unknown];
}

/// Regla de US05, US06 y US08: cuenta libres, ocupados y desconocidos; los
/// desconocidos **nunca** cuentan como libres.
class OccupancyCounter {
  const OccupancyCounter();

  OccupancyCounts count(Iterable<SpaceState> spaces) {
    var free = 0;
    var occupied = 0;
    var unknown = 0;
    for (final space in spaces) {
      switch (space.status) {
        case SpaceStatus.free:
          free++;
        case SpaceStatus.occupied:
          occupied++;
        case SpaceStatus.unknown:
          unknown++;
      }
    }
    return OccupancyCounts(free: free, occupied: occupied, unknown: unknown);
  }

  /// Conteo por zona a partir del estado de los espacios y de qué espacios
  /// pertenece a cada zona (solo identificadores: la pertenencia viene del
  /// layout). Un espacio sin estado conocido se cuenta como desconocido, no
  /// como libre.
  List<ZoneOccupancy> byZone(
    Iterable<SpaceState> spaces,
    Map<ZoneId, List<SpaceId>> membership,
  ) {
    final byId = {for (final s in spaces) s.id.value: s};
    return [
      for (final MapEntry(key: zoneId, value: members) in membership.entries)
        _zone(zoneId, [for (final id in members) byId[id.value]]),
    ];
  }

  /// Igual que [byZone], por nivel (un sótano o un piso de un pabellón).
  List<LevelOccupancy> byLevel(
    Iterable<SpaceState> spaces,
    Map<LevelId, List<SpaceId>> membership,
  ) {
    final byId = {for (final s in spaces) s.id.value: s};
    return [
      for (final MapEntry(key: levelId, value: members) in membership.entries)
        _level(levelId, [for (final id in members) byId[id.value]]),
    ];
  }

  ZoneOccupancy _zone(ZoneId zoneId, List<SpaceState?> states) {
    final counts = _count(states);
    return ZoneOccupancy(
      zoneId: zoneId,
      free: counts.free,
      occupied: counts.occupied,
      unknown: counts.unknown,
    );
  }

  LevelOccupancy _level(LevelId levelId, List<SpaceState?> states) {
    final counts = _count(states);
    return LevelOccupancy(
      levelId: levelId,
      free: counts.free,
      occupied: counts.occupied,
      unknown: counts.unknown,
    );
  }

  /// Un espacio sin estado conocido (`null`) cuenta como desconocido.
  OccupancyCounts _count(List<SpaceState?> states) {
    var free = 0;
    var occupied = 0;
    var unknown = 0;
    for (final state in states) {
      switch (state?.status) {
        case SpaceStatus.free:
          free++;
        case SpaceStatus.occupied:
          occupied++;
        case SpaceStatus.unknown || null:
          unknown++;
      }
    }
    return OccupancyCounts(free: free, occupied: occupied, unknown: unknown);
  }
}

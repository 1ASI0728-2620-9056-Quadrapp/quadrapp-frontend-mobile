// US06, US08
import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/occupancy/occupancy.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

/// Cómo se presenta la disponibilidad de un pabellón o de un nivel (la
/// píldora «Buena», «Limitada»…).
enum SpaceAvailability {
  /// Hay espacios y no se alcanza el umbral de saturación.
  good,

  /// Los ocupados alcanzaron el umbral de saturación de la sede, pero queda
  /// al menos un espacio libre.
  limited,

  /// No queda ningún espacio libre.
  full,

  /// No hay conteo, o todos los espacios están sin datos.
  noData,
}

/// Libres, ocupados y sin datos de un pabellón o un nivel. Los sin datos van
/// aparte: nunca cuentan como libres (US06 esc. 3, US08 esc. 3).
class AreaCounts extends Equatable {
  const AreaCounts({
    required this.free,
    required this.occupied,
    required this.unknown,
  });

  final int free;
  final int occupied;
  final int unknown;

  int get total => free + occupied + unknown;

  /// La disponibilidad según el umbral de saturación de la sede
  /// (`saturationThresholdPct`, el mismo que decide «casi lleno»): «limitada»
  /// cuando `ocupados ÷ (libres + ocupados) ≥ umbral`. Los sin datos quedan
  /// **fuera** del cálculo: ni libres ni ocupados.
  SpaceAvailability availability(int saturationThresholdPct) {
    final counted = free + occupied;
    if (counted == 0) return SpaceAvailability.noData;
    if (free == 0) return SpaceAvailability.full;
    return occupied * 100 >= saturationThresholdPct * counted
        ? SpaceAvailability.limited
        : SpaceAvailability.good;
  }

  @override
  List<Object?> get props => [free, occupied, unknown];
}

/// Un espacio de un nivel con su estado actual, para el mapa y la lista.
class LevelSpace extends Equatable {
  const LevelSpace({
    required this.id,
    required this.label,
    required this.status,
    this.unknownReason,
    this.posX,
    this.posY,
  });

  final SpaceId id;
  final String label;
  final SpaceStatus status;

  /// Solo tiene sentido con `status == unknown` (US08).
  final UnknownReason? unknownReason;
  final double? posX;
  final double? posY;

  @override
  List<Object?> get props => [
    id.value,
    label,
    status,
    unknownReason,
    posX,
    posY,
  ];
}

/// El estacionamiento elegido con su distribución y su ocupación en vivo: lo
/// que comparten Zonas, el pabellón y el nivel.
///
/// Una parte puede faltar sin tumbar la otra: sin ocupación se ve la
/// estructura sin conteos; sin distribución, solo los totales de la sede.
class ZonesOverview extends Equatable {
  const ZonesOverview({
    required this.lot,
    this.layout,
    this.occupancy,
    this.zoneCounts = const {},
    this.levelCounts = const {},
    this.layoutFailure,
    this.occupancyFailure,
    this.link,
  });

  final ParkingLot lot;
  final LotLayout? layout;
  final LotOccupancy? occupancy;

  /// Conteos recalculados con la distribución cada vez que cambia la
  /// ocupación (el conteo por zona de `LotOccupancy` solo vale al momento de
  /// la consulta).
  final Map<ZoneId, ZoneOccupancy> zoneCounts;
  final Map<LevelId, LevelOccupancy> levelCounts;
  final Failure? layoutFailure;
  final Failure? occupancyFailure;

  /// Estado real de la conexión en vivo; `null` si no se observa.
  final RealtimeLink? link;

  /// La sede sin distribución publicada se presenta sin disponibilidad
  /// (US04 esc. 2).
  bool get hasNoData => !lot.hasPublishedLayout;

  /// Los conteos salieron de la caché (sin conexión).
  bool get isOffline => occupancy?.isFromCache ?? false;

  bool get isPartial => !hasNoData && (layout == null || occupancy == null);

  Zone? zoneById(ZoneId id) {
    for (final zone in layout?.zones ?? const <Zone>[]) {
      if (zone.id == id) return zone;
    }
    return null;
  }

  Level? levelById(ZoneId zoneId, LevelId levelId) {
    for (final level in zoneById(zoneId)?.levels ?? const <Level>[]) {
      if (level.id == levelId) return level;
    }
    return null;
  }

  /// Los conteos de un pabellón; `null` si aún no hay ocupación.
  AreaCounts? countsOfZone(ZoneId id) {
    final counts = zoneCounts[id];
    return counts == null
        ? null
        : AreaCounts(
            free: counts.free,
            occupied: counts.occupied,
            unknown: counts.unknown,
          );
  }

  /// Los conteos de un nivel; `null` si aún no hay ocupación.
  AreaCounts? countsOfLevel(LevelId id) {
    final counts = levelCounts[id];
    return counts == null
        ? null
        : AreaCounts(
            free: counts.free,
            occupied: counts.occupied,
            unknown: counts.unknown,
          );
  }

  /// Los totales de la sede, tal como los informa el servidor.
  AreaCounts? get lotCounts {
    final value = occupancy;
    return value == null
        ? null
        : AreaCounts(
            free: value.free,
            occupied: value.occupied,
            unknown: value.unknown,
          );
  }

  /// Los espacios de [level] con su estado actual. Un espacio sin estado
  /// conocido es «sin datos», nunca libre.
  List<LevelSpace> spacesOf(Level level) {
    final byId = {
      for (final state in occupancy?.spaces ?? const <SpaceState>[])
        state.id.value: state,
    };
    return [
      for (final space in level.spaces)
        LevelSpace(
          id: space.id,
          label: space.label,
          status: byId[space.id.value]?.status ?? SpaceStatus.unknown,
          unknownReason: byId[space.id.value]?.unknownReason,
          posX: space.posX,
          posY: space.posY,
        ),
    ];
  }

  ZonesOverview copyWith({
    LotOccupancy? occupancy,
    Map<ZoneId, ZoneOccupancy>? zoneCounts,
    Map<LevelId, LevelOccupancy>? levelCounts,
    RealtimeLink? link,
  }) {
    return ZonesOverview(
      lot: lot,
      layout: layout,
      occupancy: occupancy ?? this.occupancy,
      zoneCounts: zoneCounts ?? this.zoneCounts,
      levelCounts: levelCounts ?? this.levelCounts,
      layoutFailure: layoutFailure,
      occupancyFailure: occupancyFailure,
      link: link ?? this.link,
    );
  }

  @override
  List<Object?> get props => [
    lot,
    layout,
    occupancy,
    zoneCounts,
    levelCounts,
    layoutFailure,
    occupancyFailure,
    link,
  ];
}

/// Cómo se ordenan los pabellones en Zonas.
enum ZoneOrder {
  /// Como los publica la sede (A, B, C…).
  byName,

  /// Con más espacios libres primero.
  mostFree,
}

/// Lo que elige el conductor en «Ordenar y filtrar» (estado de presentación).
class ZoneListOptions extends Equatable {
  const ZoneListOptions({
    this.order = ZoneOrder.byName,
    this.onlyWithFree = false,
  });

  final ZoneOrder order;

  /// Oculta los pabellones sin espacios libres.
  final bool onlyWithFree;

  bool get isDefault => order == ZoneOrder.byName && !onlyWithFree;

  ZoneListOptions copyWith({ZoneOrder? order, bool? onlyWithFree}) =>
      ZoneListOptions(
        order: order ?? this.order,
        onlyWithFree: onlyWithFree ?? this.onlyWithFree,
      );

  @override
  List<Object?> get props => [order, onlyWithFree];
}

/// Los pabellones de [overview] ordenados y filtrados según [options]. Sin
/// conteos (sin ocupación) no se puede filtrar ni ordenar por libres: se
/// conserva el orden de la sede.
List<Zone> arrangeZones(ZonesOverview overview, ZoneListOptions options) {
  final zones = [...?overview.layout?.zones];
  if (overview.occupancy == null) return zones;
  int freeOf(Zone zone) => overview.countsOfZone(zone.id)?.free ?? 0;
  final visible = options.onlyWithFree
      ? zones.where((zone) => freeOf(zone) > 0).toList()
      : zones;
  if (options.order == ZoneOrder.mostFree) {
    // Estable: a igual de libres, el orden de la sede.
    final indexed = [for (var i = 0; i < visible.length; i++) (i, visible[i])]
      ..sort((a, b) {
        final byFree = freeOf(b.$2).compareTo(freeOf(a.$2));
        return byFree != 0 ? byFree : a.$1.compareTo(b.$1);
      });
    return [for (final item in indexed) item.$2];
  }
  return visible;
}

import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/entities/space_state.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/entities/zone_occupancy.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/value_objects/freshness.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

/// De dónde salió el dato.
enum OccupancySource {
  /// Respuesta del servidor o cambio en tiempo real.
  network,

  /// Última copia guardada en el dispositivo (sin conexión, TS13).
  cache,
}

/// Ocupación de un estacionamiento en un momento dado (US05).
///
/// Los espacios desconocidos ([unknown]) nunca cuentan como libres.
class LotOccupancy extends Equatable {
  const LotOccupancy({
    required this.lotId,
    required this.capacity,
    required this.free,
    required this.occupied,
    required this.unknown,
    required this.freshness,
    this.zones = const [],
    this.spaces = const [],
    this.source = OccupancySource.network,
  });

  final LotId lotId;
  final int capacity;
  final int free;
  final int occupied;
  final int unknown;
  final Freshness freshness;

  /// Conteo por zona **al momento de la consulta**. Tras un cambio en tiempo
  /// real no se actualiza: se recalcula con `GetZoneSummary` y el layout.
  final List<ZoneOccupancy> zones;
  final List<SpaceState> spaces;
  final OccupancySource source;

  /// Momento al que corresponde el dato consolidado (UTC).
  DateTime get consolidatedAt => freshness.consolidatedAt;

  bool get isFromCache => source == OccupancySource.cache;

  /// No hay espacios libres (US36). Con capacidad cero no aplica.
  bool get isFull => capacity > 0 && free == 0;

  LotOccupancy copyWith({
    int? free,
    int? occupied,
    int? unknown,
    Freshness? freshness,
    List<SpaceState>? spaces,
    OccupancySource? source,
  }) {
    return LotOccupancy(
      lotId: lotId,
      capacity: capacity,
      free: free ?? this.free,
      occupied: occupied ?? this.occupied,
      unknown: unknown ?? this.unknown,
      freshness: freshness ?? this.freshness,
      zones: zones,
      spaces: spaces ?? this.spaces,
      source: source ?? this.source,
    );
  }

  @override
  List<Object?> get props => [
    lotId.value,
    capacity,
    free,
    occupied,
    unknown,
    freshness,
    zones,
    spaces,
    source,
  ];
}

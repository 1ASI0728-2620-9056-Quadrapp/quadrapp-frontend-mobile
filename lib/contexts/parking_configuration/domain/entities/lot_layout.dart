import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/entities/level.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/entities/zone.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

/// Distribución publicada de un estacionamiento (zonas, niveles y espacios),
/// con su versión (TS13).
class LotLayout extends Equatable {
  const LotLayout({
    required this.lotId,
    required this.version,
    required this.zones,
  });

  final LotId lotId;
  final int version;
  final List<Zone> zones;

  int get spaceCount => zones.fold(0, (sum, zone) => sum + zone.spaces.length);

  /// Todos los niveles, en el orden de sus zonas.
  List<Level> get levels => [for (final zone in zones) ...zone.levels];

  /// Qué espacios tiene cada zona (de todos sus niveles), solo con
  /// identificadores: es lo que necesita `occupancy` para contar por zona sin
  /// conocer las entidades de este contexto.
  Map<ZoneId, List<SpaceId>> get membership => {
    for (final zone in zones) zone.id: [for (final s in zone.spaces) s.id],
  };

  /// Qué espacios tiene cada nivel, solo con identificadores.
  Map<LevelId, List<SpaceId>> get levelMembership => {
    for (final level in levels) level.id: [for (final s in level.spaces) s.id],
  };

  /// ¿Todos los espacios tienen posición? Si no, solo se muestra la lista.
  bool get canDrawMap =>
      spaceCount > 0 &&
      zones.every((z) => z.spaces.every((s) => s.hasPosition));

  @override
  List<Object?> get props => [lotId.value, version, zones];
}

import 'package:quadrapp_mobile/contexts/occupancy/domain/entities/lot_occupancy.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/entities/space_change.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/entities/space_state.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/entities/zone_occupancy.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/value_objects/freshness.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/value_objects/space_status.dart';
import 'package:quadrapp_mobile/contexts/occupancy/infrastructure/dto/lot_occupancy_dto.dart';
import 'package:quadrapp_mobile/contexts/occupancy/infrastructure/dto/space_change_dto.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/logging/logger.dart';

/// DTO -> entidades del dominio. Un valor desconocido del servidor no rompe la
/// pantalla: el estado de un espacio cae en `UNKNOWN` (el lado seguro: nunca
/// cuenta como libre) y se registra un aviso sin datos personales.
class OccupancyMapper {
  const OccupancyMapper(this._logger);

  final Logger _logger;

  /// [receivedAt] es la lectura del reloj monótono al recibir la respuesta; si
  /// el dato sale de la caché se pasa [storedAt] y `source: cache`.
  LotOccupancy toEntity(
    LotOccupancyDto dto,
    LotId lotId, {
    Duration? receivedAt,
    DateTime? storedAt,
    OccupancySource source = OccupancySource.network,
  }) {
    final freshness = Freshness(
      consolidatedAt: dto.consolidatedAt.toUtc(),
      serverTime: dto.serverTime.toUtc(),
      staleAfter: Duration(seconds: dto.staleAfterSeconds),
      receivedAt: receivedAt,
      storedAt: storedAt,
    );
    return LotOccupancy(
      lotId: lotId,
      capacity: dto.capacity,
      free: dto.free,
      occupied: dto.occupied,
      unknown: dto.unknown,
      freshness: freshness,
      zones: [
        for (final zone in dto.zones)
          ZoneOccupancy(
            zoneId: ZoneId(zone.id),
            free: zone.free,
            occupied: zone.occupied,
            unknown: zone.unknown,
          ),
      ],
      spaces: [
        for (final space in dto.spaces)
          SpaceState(
            id: SpaceId(space.id),
            status: parseStatus(space.status),
            unknownReason: parseReason(space.unknownReason),
          ),
      ],
      source: source,
    );
  }

  SpaceChange toChange(SpaceChangeDto dto) => SpaceChange(
    eventId: dto.eventId,
    spaceId: SpaceId(dto.spaceId),
    status: parseStatus(dto.status),
    at: dto.at.toUtc(),
  );

  /// `FREE`, `OCCUPIED` y `UNKNOWN`, sin distinguir mayúsculas. Cualquier otro
  /// valor es `UNKNOWN`.
  SpaceStatus parseStatus(String raw) {
    switch (raw.toUpperCase()) {
      case 'FREE':
        return SpaceStatus.free;
      case 'OCCUPIED':
        return SpaceStatus.occupied;
      case 'UNKNOWN':
        return SpaceStatus.unknown;
    }
    _logger.warning('Estado de espacio no reconocido "$raw": se usa UNKNOWN');
    return SpaceStatus.unknown;
  }

  /// `NO_HEARTBEAT`, `LOW_BATTERY` y `NO_SENSOR`; otro valor es `null`.
  UnknownReason? parseReason(String? raw) {
    if (raw == null) return null;
    switch (raw.toUpperCase()) {
      case 'NO_HEARTBEAT':
        return UnknownReason.noHeartbeat;
      case 'LOW_BATTERY':
        return UnknownReason.lowBattery;
      case 'NO_SENSOR':
        return UnknownReason.noSensor;
    }
    _logger.warning('Motivo de estado desconocido no reconocido "$raw"');
    return null;
  }
}

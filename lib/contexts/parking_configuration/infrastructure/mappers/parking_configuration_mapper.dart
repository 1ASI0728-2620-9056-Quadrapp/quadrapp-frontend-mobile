import 'package:quadrapp_mobile/contexts/parking_configuration/domain/entities/level.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/entities/lot_layout.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/entities/parking_lot.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/entities/space.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/entities/zone.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/dto/lot_layout_dto.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/dto/parking_lot_dto.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

/// DTO -> entidades del dominio.
class ParkingConfigurationMapper {
  const ParkingConfigurationMapper();

  ParkingLot toLot(ParkingLotDto dto) => ParkingLot(
    id: LotId(dto.id),
    name: dto.name,
    address: dto.address,
    latitude: dto.latitude,
    longitude: dto.longitude,
    layoutVersion: dto.layoutVersion,
    staleAfter: Duration(seconds: dto.staleAfterSeconds),
    saturationThresholdPct:
        dto.saturationThresholdPct ?? ParkingLot.defaultSaturationThresholdPct,
  );

  /// Un texto opcional vacío o de solo espacios es "sin texto".
  String? _cleanText(String? value) {
    final text = value?.trim();
    return text == null || text.isEmpty ? null : text;
  }

  LotLayout toLayout(LotLayoutDto dto, LotId lotId) => LotLayout(
    lotId: lotId,
    version: dto.version,
    zones: [
      for (final zone in dto.zones)
        Zone(
          id: ZoneId(zone.id),
          name: zone.name,
          description: _cleanText(zone.description),
          levels: [
            for (final level in zone.levels)
              Level(
                id: LevelId(level.id),
                name: level.name,
                spaces: [
                  for (final space in level.spaces)
                    Space(
                      id: SpaceId(space.id),
                      label: space.label,
                      posX: space.posX,
                      posY: space.posY,
                    ),
                ],
              ),
          ],
        ),
    ],
  );
}

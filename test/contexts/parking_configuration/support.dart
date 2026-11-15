import 'package:quadrapp_mobile/contexts/parking_configuration/domain/entities/level.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/entities/lot_layout.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/entities/parking_lot.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/entities/space.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/entities/zone.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

ParkingLot lotEntity(
  int id, {
  int layoutVersion = 4,
  double? latitude = -12.1035,
  double? longitude = -76.9630,
}) => ParkingLot(
  id: LotId(id),
  name: 'Estacionamiento $id',
  address: 'Av. Prueba $id',
  latitude: latitude,
  longitude: longitude,
  layoutVersion: layoutVersion,
  staleAfter: const Duration(seconds: 180),
);

/// Distribución de muestra: dos zonas (el pabellón A con un sótano y el B con
/// un piso y otro) y cuatro espacios, los mismos ids que `sampleOccupancy` de
/// occupancy.
LotLayout sampleLayout({int version = 4, bool withPositions = true}) {
  Space space(int id, String label, double x, double y) => Space(
    id: SpaceId(id),
    label: label,
    posX: withPositions ? x : null,
    posY: withPositions ? y : null,
  );
  return LotLayout(
    lotId: const LotId(1),
    version: version,
    zones: [
      Zone(
        id: const ZoneId(10),
        name: 'Pabellón A',
        description: 'Edificios A–C',
        levels: [
          Level(
            id: const LevelId(100),
            name: 'Sótano 1',
            spaces: [space(1, 'A-01', 0, 0), space(2, 'A-02', 1, 0)],
          ),
        ],
      ),
      Zone(
        id: const ZoneId(11),
        name: 'Pabellón B',
        levels: [
          Level(
            id: const LevelId(110),
            name: 'Piso 1',
            spaces: [space(3, 'B-01', 0, 2)],
          ),
          Level(
            id: const LevelId(111),
            name: 'Piso 2',
            spaces: [space(4, 'B-02', 1, 2)],
          ),
        ],
      ),
    ],
  );
}

/// `GET /parking-lots` con el formato de docs/07.
Map<String, Object?> lotJson(
  int id, {
  int layoutVersion = 4,
  Object? latitude = -12.1035,
  Object? longitude = -76.963,
}) => {
  'id': id,
  'name': 'Estacionamiento $id',
  'address': 'Av. Prueba $id',
  'latitude': latitude,
  'longitude': longitude,
  'layoutVersion': layoutVersion,
  'staleAfterSeconds': 180,
};

/// `GET /parking-lots/{lotId}/layout` con el formato de docs/07.
Map<String, Object?> layoutJson({int version = 4, bool withPositions = true}) {
  Map<String, Object?> space(int id, String label, double x, double y) => {
    'id': id,
    'label': label,
    if (withPositions) ...{'posX': x, 'posY': y},
  };
  return {
    'version': version,
    'zones': [
      {
        'id': 10,
        'name': 'Pabellón A',
        'description': 'Edificios A–C',
        'levels': [
          {
            'id': 100,
            'name': 'Sótano 1',
            'spaces': [space(1, 'A-01', 0, 0), space(2, 'A-02', 1, 0)],
          },
        ],
      },
      {
        'id': 11,
        'name': 'Pabellón B',
        'levels': [
          {
            'id': 110,
            'name': 'Piso 1',
            'spaces': [space(3, 'B-01', 0, 2)],
          },
          {
            'id': 111,
            'name': 'Piso 2',
            'spaces': [space(4, 'B-02', 1, 2)],
          },
        ],
      },
    ],
  };
}

/// `ParkingLotResource` del backend (`GET /api/v1/parking-lots[/{id}]`),
/// campo por campo.
Map<String, Object?> backendLotJson(
  int id, {
  int layoutVersion = 0,
  bool active = true,
}) => {
  'id': id,
  'institutionId': 1,
  'createdBy': 1,
  'name': 'Estacionamiento $id',
  'address': 'Av. Prueba $id',
  'latitude': -12.1035,
  'longitude': -76.963,
  'opensAt': '06:00:00',
  'closesAt': '23:00:00',
  'saturationThresholdPct': 90,
  'lowBatteryThresholdPct': 20,
  'staleAfterSeconds': 180,
  'flowWindowMinutes': 15,
  'accuracyMarginPct': 10,
  'occupiedDebounceS': 10,
  'freedDebounceS': 10,
  'lowAvailabilityPct': 10,
  'layoutVersion': layoutVersion,
  'layoutPublishedAt': null,
  'active': active,
  'createdAt': '2026-11-01T12:00:00Z',
  'updatedAt': '2026-11-01T12:00:00Z',
};

/// `ZoneResource` del backend.
Map<String, Object?> backendZoneJson(int id, String name, int sortOrder) => {
  'id': id,
  'parkingLotId': 1,
  'name': name,
  'description': '',
  'sortOrder': sortOrder,
  'createdAt': '2026-11-01T12:00:00Z',
  'updatedAt': '2026-11-01T12:00:00Z',
};

/// `LevelResource` del backend.
Map<String, Object?> backendLevelJson(int id, int zoneId, String name) => {
  'id': id,
  'zoneId': zoneId,
  'name': name,
  'sortOrder': 0,
  'createdAt': '2026-11-01T12:00:00Z',
  'updatedAt': '2026-11-01T12:00:00Z',
};

/// `SpaceResource` del backend.
Map<String, Object?> backendSpaceJson(
  int id,
  int levelId,
  String label, {
  bool active = true,
}) => {
  'id': id,
  'levelId': levelId,
  'label': label,
  'type': 'STANDARD',
  'posX': 1.5,
  'posY': 2,
  'status': 'UNKNOWN',
  'unknownReason': 'NO_SENSOR',
  'statusSince': '2026-11-01T12:00:00Z',
  'lastEventAt': null,
  'active': active,
  'createdAt': '2026-11-01T12:00:00Z',
  'updatedAt': '2026-11-01T12:00:00Z',
};

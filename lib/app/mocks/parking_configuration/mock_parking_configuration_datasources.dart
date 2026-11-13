import 'dart:math' as math;

import 'package:quadrapp_mobile/app/mocks/mock_errors.dart';
import 'package:quadrapp_mobile/app/mocks/mock_world.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/datasources/layout_publish_datasource.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/datasources/lot_layout_remote_datasource.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/datasources/parking_lot_remote_datasource.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/dto/lot_layout_dto.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/dto/parking_lot_dto.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/dto/publish_layout_dto.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

/// Un estacionamiento con el formato exacto de docs/07 (`GET /parking-lots`).
Map<String, Object?> mockParkingLotJson(MockLot lot) => {
  'id': lot.id,
  'name': lot.name,
  'address': ?lot.address,
  'latitude': ?lot.latitude,
  'longitude': ?lot.longitude,
  'layoutVersion': lot.layoutVersion,
  'staleAfterSeconds': lot.staleAfterSeconds,
  'saturationThresholdPct': lot.saturationThresholdPct,
};

/// La distribución con el formato exacto de docs/07 (`GET
/// /parking-lots/{lotId}/layout`).
Map<String, Object?> mockLayoutJson(MockLot lot) => {
  'version': lot.layoutVersion,
  'zones': [
    for (final zone in lot.zones)
      {
        'id': zone.id,
        'name': zone.name,
        'description': ?zone.description,
        'levels': [
          for (final level in zone.levels)
            {
              'id': level.id,
              'name': level.name,
              'spaces': [
                for (final space in level.spaces)
                  {
                    'id': space.id,
                    'label': space.label,
                    'type': space.type,
                    'posX': space.posX,
                    'posY': space.posY,
                  },
              ],
            },
        ],
      },
  ],
};

/// Estacionamientos desde [MockWorld]. Arma el JSON con el formato de docs/07 y
/// lo lee con el mismo DTO que el datasource HTTP.
class MockParkingLotRemoteDataSource implements ParkingLotRemoteDataSource {
  const MockParkingLotRemoteDataSource(this._world);

  final MockWorld _world;

  @override
  Future<List<ParkingLotDto>> list() async {
    await _world.gate();
    return [
      for (final lot in _world.lots)
        ParkingLotDto.fromJson(mockParkingLotJson(lot)),
    ];
  }

  @override
  Future<ParkingLotDto> get(LotId lotId) async {
    await _world.gate();
    final lot = _world.lot(lotId.value);
    if (lot == null) throw mockHttpError(404, title: 'Not Found');
    return ParkingLotDto.fromJson(mockParkingLotJson(lot));
  }
}

/// Distribución desde [MockWorld]: responde 304 (`LayoutNotModified`) si la
/// versión conocida coincide con la publicada, como el backend real.
class MockLotLayoutRemoteDataSource implements LotLayoutRemoteDataSource {
  const MockLotLayoutRemoteDataSource(this._world);

  final MockWorld _world;

  @override
  Future<LayoutFetch> fetch(LotId lotId, {int? knownVersion}) async {
    await _world.gate();
    final lot = _world.lot(lotId.value);
    // Sin distribución publicada no hay layout que pedir.
    if (lot == null || !lot.hasLayout) {
      throw mockHttpError(404, title: 'Not Found');
    }
    if (knownVersion == lot.layoutVersion) return const LayoutNotModified();
    return LayoutFetched(LotLayoutDto.fromJson(mockLayoutJson(lot)));
  }
}

/// Publicación de la distribución contra [MockWorld] (US17), con las reglas de
/// docs/07: solo `ADMIN` (403 a los demás), 409 si la versión base ya no es la
/// publicada o si un nombre o código se repite. Aplica el efecto neto: crea
/// zonas, niveles y espacios (desconocidos y sin sensor hasta que la
/// plataforma les asocie uno), cambia códigos y tipos, quita del aforo los
/// deshabilitados y sube la versión.
class MockLayoutPublishDataSource implements LayoutPublishRemoteDataSource {
  const MockLayoutPublishDataSource(this._world, this._callerRole);

  final MockWorld _world;
  final String? Function() _callerRole;

  @override
  Future<PublishLayoutResponseDto> publish(
    LotId lotId,
    PublishLayoutRequestDto request,
  ) async {
    await _world.gate();
    final role = _callerRole();
    if (role == null) throw mockHttpError(401, title: 'Unauthorized');
    if (role != 'ADMIN') {
      throw mockHttpError(
        403,
        title: 'Forbidden',
        detail:
            'Solo un administrador de la universidad edita la distribución.',
      );
    }
    final lot = _world.lot(lotId.value);
    if (lot == null) throw mockHttpError(404, title: 'Not Found');
    if (request.baseVersion != lot.layoutVersion) {
      throw mockHttpError(
        409,
        title: 'Conflict',
        detail:
            'La distribución cambió: la versión publicada es la '
            '${lot.layoutVersion}.',
        extra: {'currentVersion': lot.layoutVersion},
      );
    }

    final disabled = request.disabledSpaceIds.toSet();
    final edits = {for (final e in request.updatedSpaces) e.spaceId: e};
    final labels = <String>{
      for (final space in lot.spaces)
        if (!disabled.contains(space.id))
          (edits[space.id]?.label ?? space.label).toLowerCase(),
    };
    final names = {for (final zone in lot.zones) zone.name.toLowerCase()};
    for (final zone in request.newZones) {
      if (!names.add(zone.name.toLowerCase())) {
        throw mockHttpError(
          409,
          title: 'Conflict',
          extra: {
            'errors': {
              'name': ['Ya existe una zona con ese nombre.'],
            },
          },
        );
      }
    }
    for (final space in request.newSpaces) {
      if (!labels.add(space.label.toLowerCase())) {
        throw mockHttpError(
          409,
          title: 'Conflict',
          extra: {
            'errors': {
              'label': ['El código ${space.label} ya existe.'],
            },
          },
        );
      }
    }

    // Identificadores nuevos, únicos en todo el mundo simulado.
    var zoneId = _world.lots
        .expand((l) => l.zones)
        .fold(0, (max, z) => z.id > max ? z.id : max);
    var levelId = _world.lots
        .expand((l) => l.levels)
        .fold(0, (max, l) => l.id > max ? l.id : max);
    var spaceId = _world.lots
        .expand((l) => l.spaces)
        .fold(0, (max, s) => s.id > max ? s.id : max);

    for (final space in lot.spaces) {
      final edit = edits[space.id];
      if (edit == null) continue;
      space
        ..label = edit.label
        ..type = edit.type;
    }
    for (final level in lot.levels) {
      level.spaces.removeWhere((s) => disabled.contains(s.id));
    }

    final newLevels = <String, MockLevel>{};
    for (final zone in request.newZones) {
      final level = MockLevel(id: ++levelId, name: zone.levelName, spaces: []);
      newLevels[zone.key] = level;
      lot.zones.add(MockZone(id: ++zoneId, name: zone.name, levels: [level]));
    }
    final added = <int, int>{};
    final grids = <int, ({int columns, int firstRow})>{};
    for (final space in request.newSpaces) {
      if (!space.active) continue;
      final level = space.zoneKey != null
          ? newLevels[space.zoneKey]
          : lot.levels.where((l) => l.id == space.levelId).firstOrNull;
      if (level == null) {
        throw mockHttpError(
          400,
          title: 'Bad Request',
          detail: 'Nivel inválido',
        );
      }
      // Debajo de la última fila del nivel, con sus mismas columnas (10 en
      // un nivel nuevo), para que el mapa no los encime.
      final placed = added.update(level.id, (n) => n + 1, ifAbsent: () => 0);
      final grid = grids.putIfAbsent(level.id, () {
        if (level.spaces.isEmpty) return (columns: 10, firstRow: 0);
        final maxX = level.spaces.map((s) => s.posX).reduce(math.max);
        final maxY = level.spaces.map((s) => s.posY).reduce(math.max);
        return (columns: maxX.toInt() + 1, firstRow: maxY.toInt() + 1);
      });
      level.spaces.add(
        MockSpace(
          id: ++spaceId,
          levelId: level.id,
          label: space.label,
          type: space.type,
          posX: (placed % grid.columns).toDouble(),
          posY: (grid.firstRow + placed ~/ grid.columns).toDouble(),
          status: 'UNKNOWN',
          unknownReason: 'NO_SENSOR',
        ),
      );
    }
    lot.layoutVersion++;
    return PublishLayoutResponseDto(version: lot.layoutVersion);
  }
}

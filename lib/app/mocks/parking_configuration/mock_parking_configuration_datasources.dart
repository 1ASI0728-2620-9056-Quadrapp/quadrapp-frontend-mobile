import 'package:quadrapp_mobile/app/mocks/mock_errors.dart';
import 'package:quadrapp_mobile/app/mocks/mock_world.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/datasources/lot_layout_remote_datasource.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/datasources/parking_lot_remote_datasource.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/dto/lot_layout_dto.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/dto/parking_lot_dto.dart';
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

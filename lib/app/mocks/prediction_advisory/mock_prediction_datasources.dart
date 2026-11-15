import 'package:quadrapp_mobile/app/mocks/mock_errors.dart';
import 'package:quadrapp_mobile/app/mocks/mock_world.dart';
import 'package:quadrapp_mobile/app/mocks/prediction_advisory/mock_prediction_json.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/infrastructure/datasources/prediction_remote_datasources.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/infrastructure/dto/prediction_dtos.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

const _allowedHorizons = [15, 30, 45, 60];

MockLot _requireLot(MockWorld world, int id) {
  final lot = world.lot(id);
  if (lot == null) throw mockHttpError(404, title: 'Not Found');
  return lot;
}

/// Pronósticos desde [MockWorld]: el JSON sigue docs/07 y se lee con el mismo
/// DTO que el datasource HTTP.
class MockForecastRemoteDataSource implements ForecastRemoteDataSource {
  const MockForecastRemoteDataSource(this._world);

  final MockWorld _world;

  @override
  Future<ForecastDto> fetch(LotId lotId, int horizonMinutes) async {
    await _world.gate();
    final lot = _requireLot(_world, lotId.value);
    if (!_allowedHorizons.contains(horizonMinutes)) {
      throw mockHttpError(
        400,
        title: 'Bad Request',
        extra: {'allowedHorizons': _allowedHorizons},
      );
    }
    // Un horizonte sin pronóstico responde 404 (US10 esc. 2).
    if (_world.controls.missingForecastHorizons.contains(horizonMinutes)) {
      throw mockHttpError(404, title: 'Not Found');
    }
    return ForecastDto.fromJson(mockForecastJson(_world, lot, horizonMinutes));
  }
}

/// Asesoría de llegada desde [MockWorld]. Valida el ETA como el servidor y
/// recibe solo `lotId` y `etaMinutes` (TS08 esc. 3).
class MockArrivalAdviceRemoteDataSource
    implements ArrivalAdviceRemoteDataSource {
  const MockArrivalAdviceRemoteDataSource(this._world);

  final MockWorld _world;

  @override
  Future<ArrivalAdviceDto> request(ArrivalAdviceRequestDto request) async {
    await _world.gate();
    final lot = _requireLot(_world, request.lotId);
    if (request.etaMinutes < 0 ||
        request.etaMinutes > MockPredictionRules.maxEtaMinutes) {
      throw mockHttpError(400, title: 'Bad Request');
    }
    return ArrivalAdviceDto.fromJson(
      mockAdviceJson(_world, lot, request.etaMinutes),
    );
  }
}

/// Próxima liberación desde [MockWorld] (US36).
class MockNextAvailabilityRemoteDataSource
    implements NextAvailabilityRemoteDataSource {
  const MockNextAvailabilityRemoteDataSource(this._world);

  final MockWorld _world;

  @override
  Future<NextAvailabilityDto> fetch(LotId lotId) async {
    await _world.gate();
    final lot = _requireLot(_world, lotId.value);
    return NextAvailabilityDto.fromJson(mockNextAvailabilityJson(_world, lot));
  }
}

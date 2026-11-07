import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/entities/arrival_advice.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/entities/arrival_advice_request.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/entities/forecast.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/entities/next_availability.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/repositories/arrival_advice_requester.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/repositories/forecast_reader.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/repositories/next_availability_reader.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/forecast_horizon.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/infrastructure/datasources/prediction_remote_datasources.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/infrastructure/dto/prediction_dtos.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/infrastructure/mappers/prediction_mapper.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/network/failure_mapper.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';

/// Pronósticos del servidor. Los pronósticos no se guardan en caché: solo el
/// layout y la última ocupación se usan sin conexión (TS13).
class ForecastReaderImpl implements ForecastReader {
  const ForecastReaderImpl({
    required this._remote,
    required this._mapper,
    required this._clock,
  });

  final ForecastRemoteDataSource _remote;
  final PredictionMapper _mapper;
  final Clock _clock;

  @override
  Future<Result<Forecast>> read(LotId lotId, ForecastHorizon horizon) =>
      guardResult(() async {
        final dto = await _remote.fetch(lotId, horizon.minutes);
        return _mapper.toForecast(dto, horizon, receivedAt: _clock.monotonic());
      });
}

/// La asesoría de llegada. Construye el cuerpo del request **solo** con el
/// estacionamiento y los minutos.
class ArrivalAdviceRequesterImpl implements ArrivalAdviceRequester {
  const ArrivalAdviceRequesterImpl({
    required this._remote,
    required this._mapper,
    required this._clock,
  });

  final ArrivalAdviceRemoteDataSource _remote;
  final PredictionMapper _mapper;
  final Clock _clock;

  @override
  Future<Result<ArrivalAdvice>> request(ArrivalAdviceRequest request) =>
      guardResult(() async {
        final dto = await _remote.request(
          ArrivalAdviceRequestDto(
            lotId: request.lotId.value,
            etaMinutes: request.etaMinutes.value,
          ),
        );
        return _mapper.toAdvice(dto, receivedAt: _clock.monotonic());
      });
}

/// La próxima liberación (US36).
class NextAvailabilityReaderImpl implements NextAvailabilityReader {
  const NextAvailabilityReaderImpl({
    required this._remote,
    required this._mapper,
  });

  final NextAvailabilityRemoteDataSource _remote;
  final PredictionMapper _mapper;

  @override
  Future<Result<NextAvailability>> read(LotId lotId) => guardResult(
    () async => _mapper.toNextAvailability(await _remote.fetch(lotId)),
  );
}

// US09, US10, US11, US12, TS07
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/entities/lot_forecasts.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/repositories/forecast_reader.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/forecast_horizon.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

/// Los pronósticos de un estacionamiento a 15, 30, 45 y 60 minutos, pedidos
/// en paralelo. Un horizonte sin pronóstico (404) simplemente falta; si algún
/// horizonte falla por otra causa pero otros sí llegan, se muestra lo que hay
/// (información parcial, US10 esc. 2). Solo si **ninguno** llega y hubo una
/// falla real (red, sesión), se devuelve esa falla.
///
/// Los horizontes vencidos se detectan después, con `LotForecasts.slots` y el
/// reloj, porque dependen de cuánto tiempo pasa con la pantalla abierta.
class GetLotForecasts implements UseCase<LotForecasts, LotId> {
  const GetLotForecasts(this._reader);

  final ForecastReader _reader;

  @override
  Future<Result<LotForecasts>> call(LotId lotId) async {
    final results = await Future.wait([
      for (final horizon in ForecastHorizon.values)
        _reader.read(lotId, horizon),
    ]);

    final forecasts = [for (final result in results) ?result.valueOrNull];
    if (forecasts.isNotEmpty) return Success(LotForecasts(forecasts));

    final realFailures = [
      for (final result in results)
        if (result.failureOrNull case final Failure failure
            when failure is! NotFoundFailure)
          failure,
    ];
    if (realFailures.isNotEmpty) return Err(realFailures.first);
    return const Success(LotForecasts([]));
  }
}

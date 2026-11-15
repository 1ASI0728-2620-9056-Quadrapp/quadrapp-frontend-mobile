// US10, US13, US15
import 'package:quadrapp_mobile/composition/arrival/arrival_state.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/prediction_advisory.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

/// La asesoría de cada horizonte (15, 30, 45 y 60 minutos): los minutos del
/// horizonte son el ETA de esa consulta (solo viajan el estacionamiento y los
/// minutos). Un horizonte que falla simplemente no tiene asesoría.
///
/// Lo usan Inicio («Cómo puede cambiar») y Predicción, para mostrar las mismas
/// cifras. Deuda técnica: son cuatro llamadas por pantalla; con el backend,
/// una sola del BFF (docs/07).
Future<List<HorizonAdvice>> loadHorizonAdvices(
  RequestArrivalAdvice request,
  LotId lotId,
) async {
  final results = await Future.wait([
    for (final horizon in ForecastHorizon.values)
      request(
        RequestArrivalAdviceParams(lotId: lotId, etaMinutes: horizon.minutes),
      ),
  ]);
  return [
    for (var i = 0; i < ForecastHorizon.values.length; i++)
      HorizonAdvice(ForecastHorizon.values[i], results[i].valueOrNull),
  ];
}

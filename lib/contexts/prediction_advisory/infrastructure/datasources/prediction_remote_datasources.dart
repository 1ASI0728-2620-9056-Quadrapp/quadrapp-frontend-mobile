import 'package:quadrapp_mobile/contexts/prediction_advisory/infrastructure/dto/prediction_dtos.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

/// Origen remoto de los pronósticos (HTTP o mock): mismos errores, mismos
/// formatos, mismas garantías.
// ignore: one_member_abstracts
abstract interface class ForecastRemoteDataSource {
  /// `GET /forecasts?lotId=&horizon=`. Un horizonte sin pronóstico responde
  /// 404.
  Future<ForecastDto> fetch(LotId lotId, int horizonMinutes);
}

/// Origen remoto de la asesoría de llegada (HTTP o mock).
// ignore: one_member_abstracts
abstract interface class ArrivalAdviceRemoteDataSource {
  /// `POST /arrival-advices` con el cuerpo `{ lotId, etaMinutes }` y nada más.
  Future<ArrivalAdviceDto> request(ArrivalAdviceRequestDto request);
}

/// Origen remoto de la próxima liberación (HTTP o mock).
// ignore: one_member_abstracts
abstract interface class NextAvailabilityRemoteDataSource {
  /// `GET /forecasts/{lotId}/next-availability`.
  Future<NextAvailabilityDto> fetch(LotId lotId);
}

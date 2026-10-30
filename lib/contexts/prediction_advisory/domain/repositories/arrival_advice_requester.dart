import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/entities/arrival_advice.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/entities/arrival_advice_request.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// Pide la asesoría de llegada al servidor (US13). El request lleva solo el
/// estacionamiento y los minutos (TS08).
// ignore: one_member_abstracts
abstract interface class ArrivalAdviceRequester {
  Future<Result<ArrivalAdvice>> request(ArrivalAdviceRequest request);
}

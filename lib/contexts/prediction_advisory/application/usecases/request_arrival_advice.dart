// US13, US15, TS08
import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/entities/arrival_advice.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/entities/arrival_advice_request.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/repositories/arrival_advice_requester.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/eta_minutes.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

/// Parámetros de [RequestArrivalAdvice]: el estacionamiento y el ETA. Nada más.
class RequestArrivalAdviceParams extends Equatable {
  const RequestArrivalAdviceParams({
    required this.lotId,
    required this.etaMinutes,
  });

  final LotId lotId;
  final int etaMinutes;

  @override
  List<Object?> get props => [lotId.value, etaMinutes];
}

/// Pide la asesoría de llegada. Un ETA negativo o mayor que 120 minutos no
/// genera la asesoría y se informa el motivo (`ValidationFailure`), sin llamar
/// al servidor (US13 esc. 2).
class RequestArrivalAdvice
    implements UseCase<ArrivalAdvice, RequestArrivalAdviceParams> {
  const RequestArrivalAdvice(this._requester);

  final ArrivalAdviceRequester _requester;

  @override
  Future<Result<ArrivalAdvice>> call(RequestArrivalAdviceParams params) async {
    final eta = EtaMinutes.create(params.etaMinutes);
    return switch (eta) {
      Success(:final value) => _requester.request(
        ArrivalAdviceRequest(lotId: params.lotId, etaMinutes: value),
      ),
      Err(:final failure) => Err(failure),
    };
  }
}

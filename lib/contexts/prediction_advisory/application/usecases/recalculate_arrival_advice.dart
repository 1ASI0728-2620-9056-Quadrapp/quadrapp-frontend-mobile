// US14
import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/application/usecases/request_arrival_advice.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/entities/arrival_advice.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/eta_minutes.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

/// Parámetros de [RecalculateArrivalAdvice].
class RecalculateArrivalAdviceParams extends Equatable {
  const RecalculateArrivalAdviceParams({
    required this.lotId,
    required this.newEtaMinutes,
    this.current,
  });

  final LotId lotId;

  /// El ETA recalculado (cada 60 s con la pantalla en primer plano).
  final int newEtaMinutes;

  /// La asesoría que se está mostrando, si hay.
  final ArrivalAdvice? current;

  @override
  List<Object?> get props => [lotId.value, newEtaMinutes, current];
}

/// Recalcula la asesoría cuando cambia el ETA, sin que el conductor la pida
/// (US14). Si el ETA cambió **menos de 1 minuto** respecto del de la asesoría
/// vigente, se conserva esa y no se llama al servidor. Si la vigente no es
/// utilizable (categoría desconocida), se vuelve a pedir.
class RecalculateArrivalAdvice
    implements UseCase<ArrivalAdvice, RecalculateArrivalAdviceParams> {
  const RecalculateArrivalAdvice(this._request);

  final RequestArrivalAdvice _request;

  @override
  Future<Result<ArrivalAdvice>> call(
    RecalculateArrivalAdviceParams params,
  ) async {
    final current = params.current;
    if (current != null && current.isAvailable) {
      final next = EtaMinutes.create(params.newEtaMinutes);
      final unchanged = switch (next) {
        Success(:final value) => !value.changedEnoughFrom(current.etaMinutes),
        Err() => false,
      };
      if (unchanged) return Success(current);
    }
    return _request(
      RequestArrivalAdviceParams(
        lotId: params.lotId,
        etaMinutes: params.newEtaMinutes,
      ),
    );
  }
}

// US13, US14
import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/entities/eta_estimate.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/services/eta_estimator.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/geo_point.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

/// Parámetros de [EstimateArrivalEta].
class EstimateArrivalEtaParams extends Equatable {
  const EstimateArrivalEtaParams({
    this.destination,
    this.manualMinutes,
    this.useTraffic = false,
  });

  /// Coordenadas del estacionamiento; `null` si no tiene (solo modo manual).
  final GeoPoint? destination;

  /// Lo que eligió el conductor a mano, si eligió.
  final int? manualMinutes;

  /// Con el tráfico activado, el ETA automático puede usar un proveedor de
  /// mapas.
  final bool useTraffic;

  @override
  List<Object?> get props => [destination, manualMinutes, useTraffic];
}

/// Decide el ETA: **lo manual siempre tiene prioridad** (el conductor puede
/// corregir la estimación a mano en cualquier momento); si no eligió nada, usa
/// la estimación automática. Si no se puede estimar, `Success(null)` y la app
/// sigue en modo manual, sin mostrar un error.
class EstimateArrivalEta
    implements UseCase<EtaEstimate?, EstimateArrivalEtaParams> {
  const EstimateArrivalEta({
    required this._manual,
    required this._automatic,
  });

  final EtaEstimator _manual;
  final EtaEstimator _automatic;

  @override
  Future<Result<EtaEstimate?>> call(EstimateArrivalEtaParams params) {
    final context = EtaEstimationContext(
      destination: params.destination,
      manualMinutes: params.manualMinutes,
      useTraffic: params.useTraffic,
    );
    return params.manualMinutes != null
        ? _manual.estimate(context)
        : _automatic.estimate(context);
  }
}

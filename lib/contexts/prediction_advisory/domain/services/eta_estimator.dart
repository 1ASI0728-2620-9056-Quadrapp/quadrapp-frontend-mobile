import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/entities/eta_estimate.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/geo_point.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// Lo que un [EtaEstimator] necesita para estimar el ETA.
class EtaEstimationContext extends Equatable {
  const EtaEstimationContext({
    this.destination,
    this.manualMinutes,
    this.useTraffic = false,
  });

  /// Las coordenadas del estacionamiento; `null` si no las tiene (entonces
  /// solo hay ETA manual).
  final GeoPoint? destination;

  /// Los minutos que eligió el conductor, si eligió.
  final int? manualMinutes;

  /// El conductor activó el tráfico en tiempo real: la posición (redondeada)
  /// puede ir a un proveedor de mapas. Apagado, la posición no sale del
  /// teléfono.
  final bool useTraffic;

  @override
  List<Object?> get props => [destination, manualMinutes, useTraffic];
}

/// Calcula el ETA, en minutos, en el dispositivo. Dos implementaciones:
/// `ManualEtaEstimator` (lo que elige el conductor) y `DeviceRouteEtaEstimator`
/// (con la ubicación).
// ignore: one_member_abstracts
abstract interface class EtaEstimator {
  /// `Success(null)` significa "no se pudo estimar": la app usa el modo manual
  /// **sin mostrar un error** (permiso negado, sin coordenadas, sin señal).
  /// Un `Err` es un ETA inválido (por ejemplo, mayor que 120 minutos).
  Future<Result<EtaEstimate?>> estimate(EtaEstimationContext context);
}

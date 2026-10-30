import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/eta_minutes.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

/// Lo único que se envía para pedir una asesoría: el estacionamiento y los
/// minutos de llegada (TS08). Por diseño no hay lugar para una posición.
class ArrivalAdviceRequest extends Equatable {
  const ArrivalAdviceRequest({required this.lotId, required this.etaMinutes});

  final LotId lotId;
  final EtaMinutes etaMinutes;

  @override
  List<Object?> get props => [lotId.value, etaMinutes];
}

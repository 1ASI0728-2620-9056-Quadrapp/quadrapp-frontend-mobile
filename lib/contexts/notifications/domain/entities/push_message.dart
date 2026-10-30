// US23
import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

/// Tipo de alerta push. Es lo que trae `data.type` (docs/07).
enum PushMessageType { saturation, lowArrival }

/// Un mensaje push que el conductor tocó. La app abre el inicio del
/// estacionamiento [lotId]; no hay bandeja de alertas.
class PushMessage extends Equatable {
  const PushMessage({required this.type, required this.lotId});

  final PushMessageType type;
  final LotId lotId;

  @override
  List<Object?> get props => [type, lotId.value];
}

import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/eta_minutes.dart';

/// De dónde sale el ETA.
enum EtaSource {
  /// Lo eligió el conductor.
  manual,

  /// Lo calculó un proveedor de mapas con el tráfico del momento. La posición
  /// salió del teléfono hacia el proveedor (solo con el interruptor activo).
  traffic,

  /// Lo calculó la app en el teléfono, por distancia y sin tráfico. La
  /// posición no sale del teléfono.
  device,
}

/// Un ETA y su origen.
class EtaEstimate extends Equatable {
  const EtaEstimate({required this.minutes, required this.source});

  final EtaMinutes minutes;
  final EtaSource source;

  /// Lo calculó la app (con tráfico o sin él), no lo eligió el conductor.
  bool get isEstimated => source != EtaSource.manual;

  @override
  List<Object?> get props => [minutes, source];
}

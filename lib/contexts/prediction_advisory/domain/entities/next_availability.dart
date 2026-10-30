import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/confidence.dart';

/// Tiempo estimado hasta la próxima liberación de un espacio (US36). Solo
/// aplica cuando el estacionamiento no tiene espacios libres.
sealed class NextAvailability extends Equatable {
  const NextAvailability();

  @override
  List<Object?> get props => [];
}

/// Hay una estimación: un rango de minutos con su confianza (esc. 1).
final class NextAvailabilityEstimate extends NextAvailability {
  const NextAvailabilityEstimate({
    required this.minMinutes,
    required this.maxMinutes,
    this.confidence,
  });

  final int minMinutes;
  final int maxMinutes;
  final Confidence? confidence;

  @override
  List<Object?> get props => [minMinutes, maxMinutes, confidence];
}

/// No es posible estimar el tiempo de espera, por ejemplo porque no hay
/// salidas registradas en la ventana (esc. 2).
final class NextAvailabilityNoEstimate extends NextAvailability {
  const NextAvailabilityNoEstimate();
}

/// No aplica: hay espacios libres, así que no se presenta la estimación
/// (esc. 3).
final class NextAvailabilityNotApplicable extends NextAvailability {
  const NextAvailabilityNotApplicable();
}

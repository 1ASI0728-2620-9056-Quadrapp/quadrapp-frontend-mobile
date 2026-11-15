import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/eta_assumptions.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// Minutos hasta llegar al estacionamiento (ETA). Es lo único que se envía al
/// servidor (TS08): entre 0 y [max], enteros.
class EtaMinutes extends Equatable {
  const EtaMinutes._(this.value);

  /// Mínimo admitido.
  static const int min = 0;

  /// Máximo admitido (120 min, docs/04). El servidor lo valida también (400).
  static const int max = 120;

  /// Cambio mínimo, en minutos, que justifica pedir una nueva asesoría (US14).
  /// Es [EtaAssumptions.publishThresholdMinutes]: un cambio menor es ruido del
  /// tráfico o del GPS y no vale otra consulta (docs/05, D28).
  static const int minChangeToRecalculate =
      EtaAssumptions.publishThresholdMinutes;

  final int value;

  /// Valida el ETA. Un valor negativo o mayor que [max] no genera asesoría e
  /// informa el motivo (US13 esc. 2).
  static Result<EtaMinutes> create(int minutes) {
    if (minutes < min || minutes > max) {
      return const Err(
        ValidationFailure(
          'El tiempo de llegada debe estar entre $min y $max minutos.',
          {
            'etaMinutes': ['$min..$max'],
          },
        ),
      );
    }
    return Success(EtaMinutes._(minutes));
  }

  /// ¿El cambio respecto de [other] justifica recalcular la asesoría?
  bool changedEnoughFrom(EtaMinutes other) =>
      (value - other.value).abs() >= minChangeToRecalculate;

  @override
  List<Object?> get props => [value];
}

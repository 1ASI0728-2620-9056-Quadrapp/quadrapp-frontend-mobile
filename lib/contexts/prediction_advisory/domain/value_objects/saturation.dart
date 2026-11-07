import 'package:equatable/equatable.dart';

/// Saturación prevista: el momento y el porcentaje estimado (US11 esc. 2).
class Saturation extends Equatable {
  const Saturation({required this.expectedAt, required this.pct});

  /// Momento previsto (UTC).
  final DateTime expectedAt;

  /// Porcentaje de ocupación estimado (de 0 a 100).
  final double pct;

  @override
  List<Object?> get props => [expectedAt, pct];
}

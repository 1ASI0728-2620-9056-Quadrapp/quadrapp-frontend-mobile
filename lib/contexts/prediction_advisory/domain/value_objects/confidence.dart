import 'package:equatable/equatable.dart';

/// Nivel de confianza de un pronóstico (US11, US12). **No** es la categoría de
/// llegada (`ArrivalCategory`) aunque comparta los textos `HIGH` y `LOW`.
enum ConfidenceLevel { low, medium, high }

/// Confianza de un pronóstico o de una asesoría: `{ value, level }`.
class Confidence extends Equatable {
  const Confidence({required this.value, required this.level});

  /// De 0 a 1.
  final double value;
  final ConfidenceLevel level;

  /// La confianza baja se muestra siempre, con texto y con el medidor.
  bool get isLow => level == ConfidenceLevel.low;

  @override
  List<Object?> get props => [value, level];
}

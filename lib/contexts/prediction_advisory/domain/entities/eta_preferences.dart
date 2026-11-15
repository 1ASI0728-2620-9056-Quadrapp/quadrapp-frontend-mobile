import 'package:equatable/equatable.dart';

/// Cómo quiere el conductor que se calcule su tiempo de llegada. Son
/// preferencias del teléfono (no viajan al servidor) y se borran al cerrar
/// sesión.
class EtaPreferences extends Equatable {
  const EtaPreferences({this.autoEnabled = true, this.trafficEnabled = false});

  /// Calcular el ETA con la ubicación del teléfono. Apagado, la app no usa la
  /// ubicación y solo hay ETA manual.
  final bool autoEnabled;

  /// Incluir el tráfico en tiempo real: la posición (redondeada) se envía al
  /// proveedor de mapas, no a Quadrapp. Apagado por defecto: lo activa el
  /// conductor después de leer qué se comparte.
  final bool trafficEnabled;

  EtaPreferences copyWith({bool? autoEnabled, bool? trafficEnabled}) =>
      EtaPreferences(
        autoEnabled: autoEnabled ?? this.autoEnabled,
        trafficEnabled: trafficEnabled ?? this.trafficEnabled,
      );

  @override
  List<Object?> get props => [autoEnabled, trafficEnabled];
}

// US29, TS17
import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/occupancy/occupancy.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

/// Flujo de entradas y salidas dentro de la ventana del estacionamiento
/// (`flow_window_minutes`): dos totales del periodo, no una serie.
class ShiftFlow extends Equatable {
  const ShiftFlow({
    required this.entries,
    required this.exits,
    required this.window,
  });

  final int entries;
  final int exits;
  final Duration window;

  @override
  List<Object?> get props => [entries, exits, window];
}

/// La saturación prevista: cuándo y a qué ocupación (0 a 100).
class ShiftSaturation extends Equatable {
  const ShiftSaturation({required this.expectedAt, required this.pct});

  final DateTime expectedAt;
  final double pct;

  @override
  List<Object?> get props => [expectedAt, pct];
}

/// Una sección de la consola que el servidor no pudo obtener (respuesta
/// parcial, TS17 esc. 3).
enum ShiftSection { saturation, flow }

/// El estado de operación de un estacionamiento durante el turno (US29,
/// TS17), compuesto por `GET /console/overview`. No es una entidad de un
/// contexto: combina ocupación, flujo y pronóstico para la consola de turno.
class ShiftOverview extends Equatable {
  const ShiftOverview({
    required this.lotId,
    required this.capacity,
    required this.free,
    required this.occupied,
    required this.unknown,
    required this.freshness,
    this.flow,
    this.saturation,
    this.unavailable = const {},
  });

  final LotId lotId;
  final int capacity;
  final int free;
  final int occupied;
  final int unknown;

  /// Antigüedad del dato (US29 esc. 3), con la hora del servidor.
  final Freshness freshness;

  /// `null` sin conteo de flujo habilitado o si [unavailable] lo incluye.
  final ShiftFlow? flow;

  /// `null` si no se prevé saturación o si [unavailable] la incluye.
  final ShiftSaturation? saturation;

  /// Lo que el servidor no pudo obtener.
  final Set<ShiftSection> unavailable;

  /// El pronóstico falló: la saturación es "no disponible", que no es lo
  /// mismo que "no se prevé saturación" (US29 esc. 2, TS17 esc. 3).
  bool get saturationUnavailable =>
      unavailable.contains(ShiftSection.saturation);

  bool get flowUnavailable => unavailable.contains(ShiftSection.flow);

  /// Ocupación = ocupados ÷ (libres + ocupados), **sin** los desconocidos, que
  /// se muestran aparte y nunca cuentan como libres ni como ocupados. De 0 a 1;
  /// `null` si no hay ningún espacio con dato.
  double? get occupancyFraction {
    final counted = free + occupied;
    return counted == 0 ? null : occupied / counted;
  }

  @override
  List<Object?> get props => [
    lotId.value,
    capacity,
    free,
    occupied,
    unknown,
    freshness,
    flow,
    saturation,
    unavailable,
  ];
}

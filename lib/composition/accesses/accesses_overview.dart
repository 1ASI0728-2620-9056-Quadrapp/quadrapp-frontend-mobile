// US19, US29
import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/occupancy/occupancy.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

/// Por dónde pasan los vehículos en un acceso (`accesses.type`, docs/06).
enum AccessType { entry, exit, bidirectional }

/// El estado de un acceso para el turno.
enum AccessStatus {
  /// Cuenta entradas y salidas y sus sensores de paso reportan.
  operational,

  /// Cuenta, pero algún sensor de paso no se comunica: sus cifras no están al
  /// día. También es el lado cauteloso para un estado que la app no conoce.
  unreachable,

  /// No cuenta flujo (no tiene un sensor que distinga la dirección, US19
  /// esc. 3).
  notCounting,
}

/// Un acceso vehicular y su flujo dentro de la ventana.
class VehicleAccess extends Equatable {
  const VehicleAccess({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.flowCountingEnabled,
    this.entries,
    this.exits,
  });

  final AccessId id;
  final String name;
  final AccessType type;
  final AccessStatus status;
  final bool flowCountingEnabled;

  /// `null` si el acceso no cuenta o no hay dato vigente.
  final int? entries;
  final int? exits;

  @override
  List<Object?> get props => [
    id.value,
    name,
    type,
    status,
    flowCountingEnabled,
    entries,
    exits,
  ];
}

/// Las entradas y salidas de un minuto de la ventana.
class FlowMinute extends Equatable {
  const FlowMinute({
    required this.start,
    required this.entries,
    required this.exits,
  });

  /// Inicio del minuto (UTC).
  final DateTime start;
  final int entries;
  final int exits;

  int get movements => entries + exits;

  @override
  List<Object?> get props => [start, entries, exits];
}

/// El flujo de todo el estacionamiento dentro de la ventana
/// (`flow_window_minutes`): los totales y la serie por minuto, del más antiguo
/// al más reciente (el último es el minuto en curso).
class AccessFlow extends Equatable {
  const AccessFlow({
    required this.entries,
    required this.exits,
    required this.window,
    this.minutes = const [],
  });

  final int entries;
  final int exits;
  final Duration window;
  final List<FlowMinute> minutes;

  /// Entradas menos salidas: cuántos vehículos más hay que al inicio.
  int get net => entries - exits;

  @override
  List<Object?> get props => [entries, exits, window, minutes];
}

/// Los accesos vehiculares de un estacionamiento (`GET /console/accesses`):
/// el flujo en vivo, cada acceso con su estado y la configuración propia del
/// estacionamiento. Es estado de presentación de Operación, no una entidad.
class AccessesOverview extends Equatable {
  const AccessesOverview({
    required this.lotId,
    required this.settings,
    required this.freshness,
    this.flow,
    this.accesses = const [],
    this.flowUnavailable = false,
  });

  final LotId lotId;
  final LotSettings settings;

  /// Antigüedad del flujo, con la hora del servidor.
  final Freshness freshness;

  /// `null` si ningún acceso cuenta flujo o si [flowUnavailable].
  final AccessFlow? flow;

  /// Ordenados por nombre.
  final List<VehicleAccess> accesses;

  /// El servidor no pudo obtener el flujo (respuesta parcial): no es lo mismo
  /// que «sin conteo».
  final bool flowUnavailable;

  AccessesOverview copyWith({LotSettings? settings}) => AccessesOverview(
    lotId: lotId,
    settings: settings ?? this.settings,
    freshness: freshness,
    flow: flow,
    accesses: accesses,
    flowUnavailable: flowUnavailable,
  );

  @override
  List<Object?> get props => [
    lotId.value,
    settings,
    freshness,
    flow,
    accesses,
    flowUnavailable,
  ];
}

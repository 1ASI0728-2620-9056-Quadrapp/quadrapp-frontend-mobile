import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

/// Conteo de una zona (US06). Los espacios desconocidos se cuentan aparte y
/// **nunca** como libres.
class ZoneOccupancy extends Equatable {
  const ZoneOccupancy({
    required this.zoneId,
    required this.free,
    required this.occupied,
    required this.unknown,
  });

  final ZoneId zoneId;
  final int free;
  final int occupied;
  final int unknown;

  int get total => free + occupied + unknown;

  @override
  List<Object?> get props => [zoneId.value, free, occupied, unknown];
}

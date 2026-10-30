import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

/// Conteo de un nivel (un sótano o un piso de un pabellón, US06). Los espacios
/// desconocidos se cuentan aparte y **nunca** como libres.
class LevelOccupancy extends Equatable {
  const LevelOccupancy({
    required this.levelId,
    required this.free,
    required this.occupied,
    required this.unknown,
  });

  final LevelId levelId;
  final int free;
  final int occupied;
  final int unknown;

  int get total => free + occupied + unknown;

  @override
  List<Object?> get props => [levelId.value, free, occupied, unknown];
}

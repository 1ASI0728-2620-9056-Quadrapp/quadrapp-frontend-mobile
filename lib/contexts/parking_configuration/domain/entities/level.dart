import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/entities/space.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

/// Nivel de una zona: un sótano o un piso ("Sótano 2", "Piso 1"). Los espacios
/// pertenecen a un nivel; la zona se deduce de él (US06).
class Level extends Equatable {
  const Level({required this.id, required this.name, required this.spaces});

  final LevelId id;
  final String name;
  final List<Space> spaces;

  @override
  List<Object?> get props => [id.value, name, spaces];
}

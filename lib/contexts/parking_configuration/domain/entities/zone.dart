import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/entities/level.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/entities/space.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

/// Zona de un estacionamiento (US06): un pabellón o un área de la sede
/// ("Pabellón A"), con uno o varios niveles (sótanos o pisos).
class Zone extends Equatable {
  const Zone({
    required this.id,
    required this.name,
    required this.levels,
    this.description,
  });

  final ZoneId id;
  final String name;

  /// Qué cubre la zona ("Edificios A–C"); puede faltar.
  final String? description;
  final List<Level> levels;

  /// Todos los espacios de la zona, de todos sus niveles.
  List<Space> get spaces => [for (final level in levels) ...level.spaces];

  @override
  List<Object?> get props => [id.value, name, description, levels];
}

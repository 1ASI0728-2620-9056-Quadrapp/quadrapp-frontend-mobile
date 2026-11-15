// US04 (la sede que ve el conductor)
import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';

/// Las sedes de la institución y la elegida. Es estado de presentación: cada
/// sede es un `ParkingLot` (docs/06, «Sedes, pabellones y niveles»).
class SedeSelection extends Equatable {
  const SedeSelection({required this.lots, this.selected});

  /// Todas las sedes (el estacionamiento de cada una), en el orden del
  /// servidor. Nunca vacía en un estado con datos.
  final List<ParkingLot> lots;

  /// La sede elegida; `null` si el conductor todavía no eligió una.
  final ParkingLot? selected;

  bool get hasSelection => selected != null;

  @override
  List<Object?> get props => [lots, selected];
}

import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

/// Espacio de una zona. `posX` y `posY` son posiciones en unidades de espacio
/// (columna y fila) para dibujar el mapa; pueden faltar.
class Space extends Equatable {
  const Space({
    required this.id,
    required this.label,
    this.posX,
    this.posY,
  });

  final SpaceId id;
  final String label;
  final double? posX;
  final double? posY;

  bool get hasPosition => posX != null && posY != null;

  @override
  List<Object?> get props => [id.value, label, posX, posY];
}

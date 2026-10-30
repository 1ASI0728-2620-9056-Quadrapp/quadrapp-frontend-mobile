import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/geo_point.dart';

/// Origen de la posición del dispositivo. La posición se usa solo para estimar
/// el ETA: no se envía a los servidores de Quadrapp ni se guarda.
// ignore: one_member_abstracts
abstract interface class PositionSource {
  /// La posición actual, o `null` si no se puede obtener (permiso negado,
  /// ubicación apagada, sin señal). **No** pide el permiso: eso lo hace
  /// `LocationPermissionGateway`, con una explicación previa.
  Future<GeoPoint?> currentPosition();
}

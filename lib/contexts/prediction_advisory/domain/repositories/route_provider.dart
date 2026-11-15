import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/geo_point.dart';

/// Con qué se calculó un tiempo de viaje.
enum RouteBasis {
  /// Una ruta real con el tráfico del momento (un proveedor de mapas).
  traffic,

  /// Una aproximación por distancia en línea recta, sin red ni tráfico.
  distance,
}

/// Un tiempo de viaje y con qué se calculó (de ello depende cuánta precisión
/// se muestra y cómo se le explica al conductor).
class RouteTravel extends Equatable {
  const RouteTravel({required this.duration, required this.basis});

  final Duration duration;
  final RouteBasis basis;

  @override
  List<Object?> get props => [duration, basis];
}

/// Tiempo de viaje entre dos puntos. Es la capa anticorrupción hacia lo que
/// calcule el trayecto.
///
/// Hay dos implementaciones: `LocalRouteProvider` (sin red,
/// [RouteBasis.distance]) y un proveedor de mapas con tráfico
/// ([RouteBasis.traffic], hoy Google Routes). Cambiar de proveedor es cambiar
/// una clase y su registro en `app/di`. Un proveedor de mapas recibe la
/// posición del teléfono: solo se usa si el conductor lo activó (docs/05,
/// docs/07).
// ignore: one_member_abstracts
abstract interface class RouteProvider {
  /// El tiempo de viaje, o `null` si no se pudo calcular.
  Future<RouteTravel?> travelTime({
    required GeoPoint from,
    required GeoPoint to,
  });
}

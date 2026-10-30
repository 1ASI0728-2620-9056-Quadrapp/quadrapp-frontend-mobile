import 'dart:math' as math;

import 'package:equatable/equatable.dart';

/// Un punto geográfico. Se usa **solo en el dispositivo** (la posición del
/// conductor y el destino) para estimar el ETA: no tiene `toJson` a propósito,
/// y nunca forma parte de un request.
class GeoPoint extends Equatable {
  const GeoPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  static const double _earthRadiusKm = 6371;

  /// Distancia en línea recta (fórmula de haversine), en kilómetros.
  double distanceKmTo(GeoPoint other) {
    double rad(double degrees) => degrees * math.pi / 180;
    final dLat = rad(other.latitude - latitude);
    final dLng = rad(other.longitude - longitude);
    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(latitude)) *
            math.cos(rad(other.latitude)) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * _earthRadiusKm * math.asin(math.sqrt(a));
  }

  /// Distancia en línea recta, en metros.
  double distanceMetersTo(GeoPoint other) => distanceKmTo(other) * 1000;

  /// El punto con [decimals] decimales (3 son unos 100 m): lo que se envía a un
  /// proveedor de mapas, que no necesita el punto exacto.
  GeoPoint coarsened(int decimals) {
    final factor = math.pow(10, decimals);
    return GeoPoint(
      latitude: (latitude * factor).round() / factor,
      longitude: (longitude * factor).round() / factor,
    );
  }

  @override
  List<Object?> get props => [latitude, longitude];
}

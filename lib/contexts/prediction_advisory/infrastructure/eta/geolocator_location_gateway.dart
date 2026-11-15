import 'package:geolocator/geolocator.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/repositories/location_permission_gateway.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/repositories/position_source.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/geo_point.dart';

/// Convierte el permiso de `geolocator` y el estado del servicio de ubicación
/// al estado del dominio.
LocationPermissionStatus mapLocationPermission(
  LocationPermission permission, {
  required bool serviceEnabled,
}) {
  if (!serviceEnabled) return LocationPermissionStatus.serviceDisabled;
  return switch (permission) {
    LocationPermission.always ||
    LocationPermission.whileInUse => LocationPermissionStatus.granted,
    LocationPermission.deniedForever => LocationPermissionStatus.deniedForever,
    LocationPermission.denied ||
    LocationPermission.unableToDetermine => LocationPermissionStatus.denied,
  };
}

/// La posición y el permiso de ubicación con `geolocator`. Solo primer plano:
/// una lectura puntual, de precisión media (basta para un ETA y gasta menos
/// batería). La posición se devuelve en memoria y no se guarda ni se envía.
class GeolocatorLocationGateway
    implements PositionSource, LocationPermissionGateway {
  const GeolocatorLocationGateway();

  /// Tiempo máximo para obtener la posición antes de caer al modo manual.
  static const Duration positionTimeout = Duration(seconds: 10);

  @override
  Future<LocationPermissionStatus> status() async => mapLocationPermission(
    await Geolocator.checkPermission(),
    serviceEnabled: await Geolocator.isLocationServiceEnabled(),
  );

  @override
  Future<LocationPermissionStatus> request() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    final permission = await Geolocator.requestPermission();
    return mapLocationPermission(permission, serviceEnabled: serviceEnabled);
  }

  @override
  Future<GeoPoint?> currentPosition() async {
    // No pide el permiso: eso lo hace `request`, con una explicación previa.
    if (await status() != LocationPermissionStatus.granted) return null;
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: positionTimeout,
        ),
      );
      return GeoPoint(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on Object {
      // Sin señal o tiempo agotado: el modo manual sigue disponible.
      return null;
    }
  }
}

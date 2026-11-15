import 'package:quadrapp_mobile/app/mocks/mock_controls.dart';
import 'package:quadrapp_mobile/app/mocks/mock_world.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/repositories/selected_lot_store.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/repositories/location_permission_gateway.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/repositories/position_source.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/geo_point.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';

/// La ubicación del teléfono simulada para los mocks: el permiso y su
/// resultado se controlan desde `/debug/mocks` y la posición es siempre la
/// misma (Miraflores), así el ETA automático es reproducible. Como la de
/// verdad, la posición vive en memoria: nunca se envía ni se guarda.
///
/// Con [MockControls.simulateTrip] el teléfono va manejando en línea recta
/// hacia la sede elegida a [tripSpeedKmh]: el ETA baja solo y se puede ver cómo
/// se actualiza la asesoría. Al apagarlo, vuelve a Miraflores.
class MockLocationGateway implements PositionSource, LocationPermissionGateway {
  MockLocationGateway(
    this._controls, {
    this._clock,
    this._world,
    this._selectedLot,
  });

  /// Miraflores, Lima: lejos de las cuatro sedes, a distancias distintas.
  static const GeoPoint position = GeoPoint(
    latitude: -12.1219,
    longitude: -77.0297,
  );

  /// La velocidad del viaje simulado: rápida a propósito, para ver los cambios
  /// en minutos y no en horas.
  static const double tripSpeedKmh = 150;

  final MockControls _controls;
  final Clock? _clock;
  final MockWorld? _world;
  final SelectedLotStore? _selectedLot;

  Duration? _tripStart;

  @override
  Future<LocationPermissionStatus> status() async =>
      _controls.locationPermission;

  /// Como en Android: pedir con el permiso «sin pedir» lo concede, salvo que el
  /// interruptor lo niegue; la primera negativa queda «denegado» y la
  /// siguiente, «denegado para siempre».
  @override
  Future<LocationPermissionStatus> request() async {
    final current = _controls.locationPermission;
    if (current == LocationPermissionStatus.granted ||
        current == LocationPermissionStatus.deniedForever ||
        current == LocationPermissionStatus.serviceDisabled) {
      return current;
    }
    if (!_controls.denyLocationPrompt) {
      _controls.locationPermission = LocationPermissionStatus.granted;
      return LocationPermissionStatus.granted;
    }
    _controls.locationPromptDenials++;
    return _controls.locationPermission = _controls.locationPromptDenials >= 2
        ? LocationPermissionStatus.deniedForever
        : LocationPermissionStatus.denied;
  }

  @override
  Future<GeoPoint?> currentPosition() async {
    if (_controls.locationPermission != LocationPermissionStatus.granted) {
      return null;
    }
    return await _tripPosition() ?? position;
  }

  /// Dónde va el teléfono en el viaje simulado; `null` si no hay viaje o no se
  /// conoce la sede de destino.
  Future<GeoPoint?> _tripPosition() async {
    final clock = _clock;
    if (!_controls.simulateTrip || clock == null) {
      _tripStart = null;
      return null;
    }
    final target = await _target();
    if (target == null) return null;
    final start = _tripStart ??= clock.monotonic();
    final totalKm = position.distanceKmTo(target);
    if (totalKm == 0) return target;
    final hours = (clock.monotonic() - start).inMilliseconds / 3600000;
    final progress = (hours * tripSpeedKmh / totalKm).clamp(0.0, 1.0);
    return GeoPoint(
      latitude:
          position.latitude + (target.latitude - position.latitude) * progress,
      longitude:
          position.longitude +
          (target.longitude - position.longitude) * progress,
    );
  }

  Future<GeoPoint?> _target() async {
    final id = await _selectedLot?.read();
    final lot = id == null ? null : _world?.lot(id.value);
    final lat = lot?.latitude;
    final lng = lot?.longitude;
    return lat == null || lng == null
        ? null
        : GeoPoint(latitude: lat, longitude: lng);
  }
}

import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

/// Estacionamiento de la institución (US04). La app solo lo lee: registrarlo y
/// editarlo es de la consola.
class ParkingLot extends Equatable {
  const ParkingLot({
    required this.id,
    required this.name,
    required this.layoutVersion,
    required this.staleAfter,
    this.saturationThresholdPct = defaultSaturationThresholdPct,
    this.address,
    this.latitude,
    this.longitude,
  });

  final LotId id;
  final String name;
  final String? address;

  /// Destino para calcular el ETA en el dispositivo (la posición del usuario
  /// nunca sale de él). Pueden faltar (docs/06: son opcionales): sin ellas
  /// solo hay ETA manual.
  final double? latitude;
  final double? longitude;

  /// Versión de la distribución publicada; 0 = sin distribución publicada.
  final int layoutVersion;

  /// Umbral de vigencia de los datos de ocupación de este estacionamiento.
  final Duration staleAfter;

  /// Umbral de saturación del estacionamiento (`saturation_threshold_pct`,
  /// docs/06), de 1 a 100: con él se decide cuándo está "casi lleno".
  final int saturationThresholdPct;

  /// El valor por defecto de docs/06.
  static const int defaultSaturationThresholdPct = 90;

  /// ¿Tiene distribución publicada? Si no, se presenta sin información de
  /// disponibilidad (US04 esc. 2).
  bool get hasPublishedLayout => layoutVersion > 0;

  /// ¿Se puede calcular el ETA en el dispositivo hacia este estacionamiento?
  bool get hasCoordinates => latitude != null && longitude != null;

  @override
  List<Object?> get props => [
    id.value,
    name,
    address,
    latitude,
    longitude,
    layoutVersion,
    staleAfter,
    saturationThresholdPct,
  ];
}

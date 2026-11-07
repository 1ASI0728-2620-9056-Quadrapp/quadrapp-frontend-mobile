// US13 (mapa de la llegada); TS08 (la posición no llega a Quadrapp)
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/prediction_advisory.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

/// Lo que dibuja el mapa de Inicio: la sede y, si el conductor usa su
/// ubicación, desde dónde viene (redondeado a unos 100 m).
class ArrivalMapState extends Equatable {
  const ArrivalMapState({this.lotName, this.destination, this.origin});

  final String? lotName;

  /// La sede; `null` si no tiene coordenadas (no hay mapa).
  final GeoPoint? destination;

  /// La posición aproximada del conductor; `null` si no se usa su ubicación.
  final GeoPoint? origin;

  bool get hasMap => destination != null;

  @override
  List<Object?> get props => [lotName, destination, origin];
}

/// Decide qué muestra el mapa de Inicio. La posición solo se lee si el
/// conductor tiene encendido «Calcular mi llegada automáticamente» y ya dio el
/// permiso (nunca se pide desde aquí). Va solo a Google, para dibujar el mapa;
/// a Quadrapp nunca llega.
class ArrivalMapCubit extends Cubit<ArrivalMapState> {
  ArrivalMapCubit({required this._getPosition})
    : super(const ArrivalMapState());

  final GetApproximatePosition _getPosition;

  int _request = 0;

  /// Vuelve a calcular el mapa para [lot]; con [useLocation], con la posición
  /// aproximada del conductor.
  Future<void> sync({
    required ParkingLot? lot,
    required bool useLocation,
  }) async {
    final request = ++_request;
    final destination = _destinationOf(lot);
    if (destination == null || !useLocation) {
      emit(ArrivalMapState(lotName: lot?.name, destination: destination));
      return;
    }
    final origin = switch (await _getPosition(const NoParams())) {
      Success(:final value) => value,
      Err() => null,
    };
    // Solo vale la última petición (la sede pudo cambiar mientras tanto).
    if (isClosed || request != _request) return;
    emit(
      ArrivalMapState(
        lotName: lot?.name,
        destination: destination,
        origin: origin,
      ),
    );
  }

  static GeoPoint? _destinationOf(ParkingLot? lot) {
    final latitude = lot?.latitude;
    final longitude = lot?.longitude;
    if (latitude == null || longitude == null) return null;
    return GeoPoint(latitude: latitude, longitude: longitude);
  }
}

/// La URL del mapa incrustado de Google (`output=embed`, no necesita clave):
/// la sede con un marcador o, con [ArrivalMapState.origin], la ruta desde ahí.
/// Los textos del mapa van en [languageCode].
Uri embeddedMapUri(ArrivalMapState state, String languageCode) {
  String point(GeoPoint p) => '${p.latitude},${p.longitude}';
  final destination = state.destination!;
  final origin = state.origin;
  return Uri.https('maps.google.com', '/maps', {
    if (origin == null) ...{
      'q': point(destination),
      'z': '16',
    } else ...{
      'saddr': point(origin),
      'daddr': point(destination),
    },
    'hl': languageCode,
    'output': 'embed',
  });
}

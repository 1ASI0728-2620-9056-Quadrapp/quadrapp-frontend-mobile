import 'package:dio/dio.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/repositories/route_provider.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/geo_point.dart';

/// Tiempo de viaje **con tráfico** de Google Routes (`computeRoutes`, tarifa
/// «Pro» por `TRAFFIC_AWARE`). Solo se usa si el conductor activó el tráfico:
/// la posición (ya redondeada por quien llama) sale del teléfono hacia Google.
/// Quadrapp no la recibe.
///
/// - Usa su **propio** `Dio`, sin la sesión de Quadrapp ni registro de
///   peticiones: no se envía ningún `Authorization` de Quadrapp a Google y la
///   clave y las coordenadas nunca llegan a los logs.
/// - Cualquier fallo (sin red, tiempo agotado, cuota, clave rechazada,
///   respuesta ilegible) devuelve `null`: quien llama cae a la estimación local
///   sin mostrar un error.
/// - La clave se restringe a la API Routes en la consola de Google, con cuota y
///   alerta de presupuesto; como viaja en la app, se trata como pública.
class GoogleRoutesProvider implements RouteProvider {
  GoogleRoutesProvider({required this._dio, required this._apiKey});

  /// Cliente propio, sin interceptores de Quadrapp.
  static Dio newClient() => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      sendTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 6),
    ),
  );

  static const String endpoint =
      'https://routes.googleapis.com/directions/v2:computeRoutes';

  final Dio _dio;
  final String _apiKey;

  @override
  Future<RouteTravel?> travelTime({
    required GeoPoint from,
    required GeoPoint to,
  }) async {
    try {
      final response = await _dio.post<Object?>(
        endpoint,
        data: {
          'origin': _waypoint(from),
          'destination': _waypoint(to),
          'travelMode': 'DRIVE',
          'routingPreference': 'TRAFFIC_AWARE',
        },
        options: Options(
          contentType: Headers.jsonContentType,
          headers: {
            'X-Goog-Api-Key': _apiKey,
            // Solo la duración: menos datos y sin campos de otra tarifa.
            'X-Goog-FieldMask': 'routes.duration',
          },
        ),
      );
      final seconds = _seconds(response.data);
      return seconds == null
          ? null
          : RouteTravel(
              duration: Duration(seconds: seconds),
              basis: RouteBasis.traffic,
            );
    } on Object {
      return null;
    }
  }

  static Map<String, Object?> _waypoint(GeoPoint point) => {
    'location': {
      'latLng': {'latitude': point.latitude, 'longitude': point.longitude},
    },
  };

  /// `{"routes":[{"duration":"1523s"}]}` → 1523; cualquier otra forma, `null`.
  static int? _seconds(Object? data) {
    if (data is! Map<String, dynamic>) return null;
    final routes = data['routes'];
    if (routes is! List<dynamic> || routes.isEmpty) return null;
    final first = routes.first;
    if (first is! Map<String, dynamic>) return null;
    final duration = first['duration'];
    if (duration is! String) return null;
    final match = RegExp(r'^(\d+(?:\.\d+)?)s$').firstMatch(duration);
    if (match == null) return null;
    return double.parse(match.group(1)!).round();
  }
}

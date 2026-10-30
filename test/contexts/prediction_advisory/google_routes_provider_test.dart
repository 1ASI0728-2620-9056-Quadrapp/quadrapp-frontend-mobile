// US13, US14: el proveedor de Google Routes y lo que envía.
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/repositories/route_provider.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/geo_point.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/infrastructure/eta/google_routes_provider.dart';

import '../../helpers/fake_http_adapter.dart';

const _from = GeoPoint(latitude: -12.123, longitude: -77.03);
const _to = GeoPoint(latitude: -12.1035, longitude: -76.963);

void main() {
  GoogleRoutesProvider providerOn(FakeHttpAdapter adapter) =>
      GoogleRoutesProvider(dio: dioWith(adapter), apiKey: 'clave-de-prueba');

  test('caso feliz: la duración llega como segundos con tráfico', () async {
    final adapter = FakeHttpAdapter(
      (_) => jsonResponse({
        'routes': [
          {'duration': '1523s'},
        ],
      }),
    );

    final travel = await providerOn(adapter).travelTime(from: _from, to: _to);

    expect(travel?.duration, const Duration(seconds: 1523));
    expect(travel?.basis, RouteBasis.traffic);
  });

  test(
    'envía solo origen, destino y modo; la clave va en el encabezado',
    () async {
      final adapter = FakeHttpAdapter(
        (_) => jsonResponse({
          'routes': [
            {'duration': '600s'},
          ],
        }),
      );

      await providerOn(adapter).travelTime(from: _from, to: _to);

      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.uri.toString(), GoogleRoutesProvider.endpoint);
      expect(request.headers['X-Goog-Api-Key'], 'clave-de-prueba');
      // Solo la duración: menos datos y ningún campo de otra tarifa.
      expect(request.headers['X-Goog-FieldMask'], 'routes.duration');
      // Nada de Quadrapp viaja a Google.
      expect(request.headers.containsKey('Authorization'), isFalse);
      expect(request.data, {
        'origin': {
          'location': {
            'latLng': {'latitude': -12.123, 'longitude': -77.03},
          },
        },
        'destination': {
          'location': {
            'latLng': {'latitude': -12.1035, 'longitude': -76.963},
          },
        },
        'travelMode': 'DRIVE',
        'routingPreference': 'TRAFFIC_AWARE',
      });
    },
  );

  test('la duración con decimales se redondea', () async {
    final adapter = FakeHttpAdapter(
      (_) => jsonResponse({
        'routes': [
          {'duration': '90.6s'},
        ],
      }),
    );

    final travel = await providerOn(adapter).travelTime(from: _from, to: _to);

    expect(travel?.duration, const Duration(seconds: 91));
  });

  group('cualquier fallo es null, sin excepción', () {
    for (final (name, handler) in <(String, HttpHandler)>[
      (
        'clave rechazada (403)',
        (_) => jsonResponse({'error': <String, Object?>{}}, status: 403),
      ),
      (
        'cuota agotada (429)',
        (_) => jsonResponse({'error': <String, Object?>{}}, status: 429),
      ),
      (
        'error del servidor (500)',
        (_) => jsonResponse(<String, Object?>{}, status: 500),
      ),
      ('sin rutas', (_) => jsonResponse({'routes': <Object?>[]})),
      ('respuesta vacía', (_) => jsonResponse(<String, Object?>{})),
      (
        'duración ilegible',
        (_) => jsonResponse({
          'routes': [
            {'duration': 'rápido'},
          ],
        }),
      ),
      (
        'no es un objeto',
        (_) => jsonResponse(<Object?>[1, 2]),
      ),
      (
        'sin red',
        (options) => throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      ),
      (
        'tiempo agotado',
        (options) => throw DioException(
          requestOptions: options,
          type: DioExceptionType.receiveTimeout,
        ),
      ),
    ]) {
      test(name, () async {
        final travel = await providerOn(
          FakeHttpAdapter(handler),
        ).travelTime(from: _from, to: _to);

        expect(travel, isNull);
      });
    }
  });
}

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:quadrapp_mobile/app/config/app_config.dart';
import 'package:quadrapp_mobile/app/di/injector.dart';
import 'package:quadrapp_mobile/app/di/occupancy_module.dart';
import 'package:quadrapp_mobile/app/di/registrar.dart';
import 'package:quadrapp_mobile/app/mocks/mock_world.dart';
import 'package:quadrapp_mobile/app/mocks/occupancy/mock_occupancy_datasources.dart';
import 'package:quadrapp_mobile/app/session/pending_removal_retrier.dart';
import 'package:quadrapp_mobile/app/session/session_expiry_coordinator.dart';
import 'package:quadrapp_mobile/app/startup.dart';
import 'package:quadrapp_mobile/composition/sign_out/sign_out.dart';
import 'package:quadrapp_mobile/contexts/iam/application/usecases/refresh_session.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/repositories/push_gateway.dart';
import 'package:quadrapp_mobile/contexts/notifications/infrastructure/push/unavailable_push_gateway.dart';
import 'package:quadrapp_mobile/contexts/notifications/infrastructure/repositories/pending_push_token_removal_store_impl.dart';
import 'package:quadrapp_mobile/contexts/occupancy/infrastructure/datasources/occupancy_http_datasource.dart';
import 'package:quadrapp_mobile/contexts/occupancy/infrastructure/datasources/occupancy_realtime_datasource.dart';
import 'package:quadrapp_mobile/contexts/occupancy/infrastructure/datasources/occupancy_remote_datasource.dart';
import 'package:quadrapp_mobile/contexts/occupancy/infrastructure/datasources/occupancy_ws_datasource.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/network/web_socket_connector.dart';
import 'package:quadrapp_mobile/core/storage/key_value_store.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../contexts/notifications/support.dart' as notifications;
import '../../helpers/fake_http_adapter.dart';
import '../../helpers/test_seed.dart';

class _RecordingConnector implements WebSocketConnector {
  final List<Uri> connections = [];

  @override
  WebSocketChannel connect(Uri uri, {Map<String, String> headers = const {}}) {
    connections.add(uri);
    throw StateError('Construir no debe abrir un WebSocket.');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GetIt locator;

  setUp(() {
    locator = GetIt.asNewInstance();
  });

  tearDown(() => locator.reset());

  for (final useMocks in [true, false]) {
    group('con USE_MOCKS=$useMocks', () {
      final config = AppConfig(
        useMocks: useMocks,
        apiBaseUrl: 'https://api.test/api/v1',
      );

      test('todas las dependencias se resuelven sin llamadas de red', () async {
        await configureDependencies(
          config: config,
          locator: locator,
          // El almacén real (`shared_preferences`) necesita la plataforma del
          // plugin, que no existe en las pruebas.
          keyValueStore: InMemoryKeyValueStore(),
          mockSeed: testSeed,
        );
        // Nada debe salir a la red al construir: se vigila el cliente HTTP y
        // el conector WebSocket (ambos se construyen perezosamente).
        final adapter = FakeHttpAdapter(
          (_) => throw StateError('Construir no debe llamar al servidor.'),
        );
        locator<Dio>().httpClientAdapter = adapter;
        final connector = _RecordingConnector();
        locator
          ..unregister<WebSocketConnector>()
          ..registerLazySingleton<WebSocketConnector>(() => connector);

        final resolved = locator.resolveAll();

        expect(resolved.length, locator.trackedTypes.length);
        expect(resolved.keys, containsAll(<Type>[SignOut, RefreshSession]));
        expect(
          resolved.keys,
          containsAll(<Type>[PendingRemovalRetrier, SessionExpiryCoordinator]),
        );
        expect(adapter.requests, isEmpty);
        expect(connector.connections, isEmpty);
      });

      test('elige mocks o HTTP/WebSocket según USE_MOCKS', () async {
        await configureDependencies(
          config: config,
          locator: locator,
          // El almacén real (`shared_preferences`) necesita la plataforma del
          // plugin, que no existe en las pruebas.
          keyValueStore: InMemoryKeyValueStore(),
          mockSeed: testSeed,
        );

        expect(locator.isRegistered<MockWorld>(), useMocks);
        expect(
          locator<OccupancyRemoteDataSource>(),
          useMocks
              ? isA<MockOccupancyRemoteDataSource>()
              : isA<OccupancyHttpDataSource>(),
        );
        expect(
          locator<OccupancyRealtimeDataSource>(),
          useMocks
              ? isA<MockOccupancyRealtimeDataSource>()
              : isA<OccupancyWsDataSource>(),
        );
        // Sin Firebase (fase 6), el modo real no inventa un token push.
        if (!useMocks) {
          expect(locator<PushGateway>(), isA<UnavailablePushGateway>());
        }
      });
    });
  }

  test('occupancySocketUri deriva ws/wss de la URL base de la API', () {
    expect(
      occupancySocketUri('http://10.0.2.2:8080/api/v1', const LotId(7)),
      Uri.parse('ws://10.0.2.2:8080/api/v1/ws/parking-lots/7'),
    );
    expect(
      occupancySocketUri('https://api.test/api/v1/', const LotId(7)),
      Uri.parse('wss://api.test/api/v1/ws/parking-lots/7'),
    );
  });

  group('startAppServices', () {
    test('reintenta la baja pendiente del token push al arrancar', () async {
      final values = InMemoryKeyValueStore();
      final pending = PendingPushTokenRemovalStoreImpl(values);
      await pending.save(notifications.pushToken('t-1'));
      await configureDependencies(
        config: const AppConfig(useMocks: true, apiBaseUrl: 'https://x.test'),
        locator: locator,
        keyValueStore: values,
        mockSeed: testSeed,
      );

      startAppServices(locator);

      // El mock responde con latencia simulada (200 a 600 ms).
      for (var i = 0; i < 40 && await pending.read() != null; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      expect(await pending.read(), isNull);
    });
  });
}

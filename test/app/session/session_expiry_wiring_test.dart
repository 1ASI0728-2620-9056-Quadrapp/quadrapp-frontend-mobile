// US03: el 401 con refresh rechazado llega, por el contenedor real, hasta el
// cierre de sesión local y el aviso para el router.
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:quadrapp_mobile/app/config/app_config.dart';
import 'package:quadrapp_mobile/app/di/injector.dart';
import 'package:quadrapp_mobile/app/session/session_expiry_coordinator.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/repositories/access_token_holder.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/repositories/session_store.dart';
import 'package:quadrapp_mobile/contexts/iam/iam.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/application/usecases/list_parking_lots.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/storage/key_value_store.dart';
import 'package:quadrapp_mobile/core/storage/secure_store.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

import '../../contexts/iam/support.dart';
import '../../helpers/fake_http_adapter.dart';

void main() {
  late GetIt locator;
  late InMemoryKeyValueStore values;
  late FakeHttpAdapter server;
  late SessionExpiryCoordinator coordinator;
  late int expiredEvents;

  /// El servidor: rechaza el token de acceso y también el refresh token.
  Future<void> bootWith(ResponseBody Function(RequestOptions) handler) async {
    locator = GetIt.asNewInstance();
    values = InMemoryKeyValueStore();
    await configureDependencies(
      config: const AppConfig(
        useMocks: false,
        apiBaseUrl: 'https://api.test/api/v1',
      ),
      locator: locator,
      keyValueStore: values,
      secureStore: InMemorySecureStore(),
    );
    server = FakeHttpAdapter(handler);
    locator<Dio>().httpClientAdapter = server;
    expiredEvents = 0;
    locator<WatchSessionExpiry>()().listen((_) => expiredEvents++);

    await locator<SessionStore>().save(sampleStored());
    locator<AccessTokenHolder>().replace(accessToken('vencido'));
    await values.setString('user.selectedLot', '2');
    await values.setString('cache.layout.1', '{}');
    await values.setString('device.language', 'es');

    coordinator = locator<SessionExpiryCoordinator>()..start();
  }

  tearDown(() => locator.reset());

  test(
    'refresh rechazado: limpia el dispositivo y avisa al router una vez',
    () async {
      await bootWith((options) => jsonResponse({'title': 'x'}, status: 401));
      final notified = Completer<void>();
      coordinator.addListener(() {
        if (!notified.isCompleted) notified.complete();
      });

      final result = await locator<ListParkingLots>()(const NoParams());
      await notified.future.timeout(const Duration(seconds: 2));

      expect(result.failureOrNull, isA<UnauthorizedFailure>());
      // Un solo refresh; sin `POST /auth/logout`: la sesión ya no era válida.
      expect(
        server.requests.map((r) => r.path),
        containsAllInOrder(['/parking-lots', '/auth/refresh']),
      );
      expect(
        server.requests.map((r) => r.path),
        isNot(contains('/auth/logout')),
      );
      expect(expiredEvents, 1);
      // Limpieza local completa; el idioma se conserva.
      expect(coordinator.hasExpired, isTrue);
      expect(await locator<SessionStore>().read(), isNull);
      expect(locator<AccessTokenHolder>().current, isNull);
      expect(await values.getString('user.selectedLot'), isNull);
      expect(await values.getString('cache.layout.1'), isNull);
      expect(await values.getString('device.language'), 'es');

      coordinator.acknowledge();
      expect(coordinator.hasExpired, isFalse);
    },
  );

  test('sin red al renovar: la sesión se conserva', () async {
    await bootWith((options) {
      if (options.path == '/auth/refresh') {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      }
      return jsonResponse({'title': 'x'}, status: 401);
    });

    await locator<ListParkingLots>()(const NoParams());
    await Future<void>.delayed(Duration.zero);

    expect(coordinator.hasExpired, isFalse);
    expect(expiredEvents, 0);
    expect(await locator<SessionStore>().read(), isNotNull);
    expect(await values.getString('user.selectedLot'), '2');
  });
}

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quadrapp_mobile/app/session/pending_removal_retrier.dart';
import 'package:quadrapp_mobile/app/session/session_token_source.dart';
import 'package:quadrapp_mobile/contexts/iam/application/usecases/expire_session.dart';
import 'package:quadrapp_mobile/contexts/iam/application/usecases/refresh_session.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/repositories/auth_repository.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/refresh_token.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/mappers/iam_mapper.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/repositories/in_memory_access_token_holder.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/repositories/session_store_impl.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/repositories/stream_session_events.dart';
import 'package:quadrapp_mobile/contexts/notifications/application/usecases/pending_token_removal_usecases.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/repositories/device_token_repository.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/value_objects/push_token.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/network/auth_interceptor.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/storage/key_value_store.dart';
import 'package:quadrapp_mobile/core/storage/secure_store.dart';

import '../../contexts/iam/support.dart';
import '../../contexts/notifications/support.dart' as notifications;
import '../../helpers/fake_http_adapter.dart';
import '../../helpers/recording_logger.dart';

class _MockAuth extends Mock implements AuthRepository {}

class _MockDevices extends Mock implements DeviceTokenRepository {}

class _FakeRefreshToken extends Fake implements RefreshToken {}

class _FakePushToken extends Fake implements PushToken {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeRefreshToken());
    registerFallbackValue(_FakePushToken());
  });

  group('SessionTokenSource + AuthInterceptor + RefreshSession', () {
    late _MockAuth auth;
    late InMemoryAccessTokenHolder holder;
    late SessionStoreImpl sessions;
    late StreamSessionEvents events;
    late int expiredCallbacks;

    setUp(() async {
      auth = _MockAuth();
      holder = InMemoryAccessTokenHolder()..replace(accessToken('OLD'));
      sessions = SessionStoreImpl(
        values: InMemoryKeyValueStore(),
        secrets: InMemorySecureStore(),
        mapper: IamMapper(RecordingLogger()),
      );
      await sessions.save(sampleStored());
      events = StreamSessionEvents();
      expiredCallbacks = 0;
    });

    tearDown(() => events.dispose());

    Dio build(FakeHttpAdapter adapter) {
      final expire = ExpireSession(
        sessions: sessions,
        accessToken: holder,
        events: events,
      );
      final dio = dioWith(adapter);
      dio.interceptors.add(
        AuthInterceptor(
          dio: dio,
          tokens: SessionTokenSource(
            accessToken: holder,
            refresh: RefreshSession(
              auth: auth,
              sessions: sessions,
              accessToken: holder,
              expire: expire,
            ),
          ),
          onSessionExpired: () => expiredCallbacks++,
        ),
      );
      return dio;
    }

    FakeHttpAdapter serverAccepting(String token) => FakeHttpAdapter(
      (options) => options.headers['Authorization'] == 'Bearer $token'
          ? jsonResponse({'ok': true})
          : jsonResponse({'title': 'expired'}, status: 401),
    );

    test(
      'varias peticiones con 401 comparten un solo refresh y se reintentan',
      () async {
        final gate = Completer<void>();
        final refreshStarted = Completer<void>();
        when(() => auth.refresh(any())).thenAnswer((_) async {
          if (!refreshStarted.isCompleted) refreshStarted.complete();
          await gate.future;
          return Success(accessToken('NEW'));
        });
        final adapter = serverAccepting('NEW');
        final dio = build(adapter);

        final calls = Future.wait([
          dio.get<dynamic>('/a'),
          dio.get<dynamic>('/b'),
          dio.get<dynamic>('/c'),
        ]);
        // Espera a que las tres peticiones hayan fallado con 401 mientras el
        // refresh sigue en curso, sin depender de tiempos fijos.
        await refreshStarted.future;
        while (adapter.requests.length < 3) {
          await Future<void>.delayed(Duration.zero);
        }
        await Future<void>.delayed(const Duration(milliseconds: 50));
        gate.complete();
        final responses = await calls;

        expect(responses.map((r) => r.statusCode), [200, 200, 200]);
        verify(() => auth.refresh(any())).called(1);
        expect(holder.current, accessToken('NEW'));
        expect(expiredCallbacks, 0);
      },
    );

    test('refresh rechazado (401): la sesión expira', () async {
      when(
        () => auth.refresh(any()),
      ).thenAnswer((_) async => const Err(UnauthorizedFailure()));
      final dio = build(serverAccepting('NEW'));
      var notified = 0;
      final subscription = events.expired.listen((_) => notified++);

      await expectLater(dio.get<dynamic>('/a'), throwsA(isA<DioException>()));
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(expiredCallbacks, 1);
      expect(notified, 1);
      expect(await sessions.read(), isNull);
    });

    test('refresh sin red: la sesión se conserva', () async {
      when(
        () => auth.refresh(any()),
      ).thenAnswer((_) async => const Err(NetworkFailure()));
      final dio = build(serverAccepting('NEW'));

      await expectLater(dio.get<dynamic>('/a'), throwsA(isA<DioException>()));

      expect(expiredCallbacks, 0);
      expect(await sessions.read(), isNotNull);
      expect(holder.current, accessToken('OLD'));
    });
  });

  group('PendingRemovalRetrier (arranque y primer plano)', () {
    late _MockDevices devices;
    late notifications.MemoryPendingRemovalStore pending;
    late PendingRemovalRetrier retrier;

    setUp(() {
      devices = _MockDevices();
      pending = notifications.MemoryPendingRemovalStore()
        ..pending = notifications.pushToken('t-1');
      retrier = PendingRemovalRetrier(
        RetryPendingTokenRemoval(devices: devices, pendingRemovals: pending),
      );
      when(
        () => devices.unregister(any()),
      ).thenAnswer((_) async => const Success<void>(null));
    });

    testWidgets('reintenta al arrancar', (tester) async {
      await retrier.start();

      verify(
        () => devices.unregister(notifications.pushToken('t-1')),
      ).called(1);
      expect(pending.pending, isNull);
      retrier.dispose();
    });

    testWidgets('reintenta cada vez que la app vuelve a primer plano', (
      tester,
    ) async {
      when(
        () => devices.unregister(any()),
      ).thenAnswer((_) async => const Err(NetworkFailure()));
      await retrier.start();
      verify(() => devices.unregister(any())).called(1);

      final binding = tester.binding
        ..handleAppLifecycleStateChanged(AppLifecycleState.paused);
      // Pasar a segundo plano no reintenta.
      await tester.pump();
      verifyNever(() => devices.unregister(any()));

      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      verify(() => devices.unregister(any())).called(1);
      // Un fallo de red conserva el registro para el próximo intento.
      expect(pending.pending, notifications.pushToken('t-1'));

      binding
        ..handleAppLifecycleStateChanged(AppLifecycleState.paused)
        ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      verify(() => devices.unregister(any())).called(1);
      retrier.dispose();
    });

    testWidgets('nunca hay dos reintentos a la vez', (tester) async {
      final gate = Completer<void>();
      when(() => devices.unregister(any())).thenAnswer((_) async {
        await gate.future;
        return const Success<void>(null);
      });

      final first = retrier.retry();
      final second = retrier.retry();
      gate.complete();
      await Future.wait([first, second]);

      verify(() => devices.unregister(any())).called(1);
    });

    testWidgets('sin baja pendiente no llama al servidor', (tester) async {
      pending.pending = null;

      await retrier.retry();

      verifyNever(() => devices.unregister(any()));
    });
  });
}

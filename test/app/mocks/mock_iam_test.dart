import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/app/mocks/iam/mock_auth_datasource.dart';
import 'package:quadrapp_mobile/app/mocks/iam/mock_iam_state.dart';
import 'package:quadrapp_mobile/app/mocks/mock_controls.dart';
import 'package:quadrapp_mobile/app/mocks/mock_world.dart';
import 'package:quadrapp_mobile/app/mocks/notifications/mock_notification_datasources.dart';
import 'package:quadrapp_mobile/app/mocks/notifications/stub_push_gateway.dart';
import 'package:quadrapp_mobile/app/mocks/parking_configuration/mock_parking_configuration_datasources.dart';
import 'package:quadrapp_mobile/composition/sign_out/sign_out.dart';
import 'package:quadrapp_mobile/contexts/iam/application/usecases/expire_session.dart';
import 'package:quadrapp_mobile/contexts/iam/application/usecases/refresh_session.dart';
import 'package:quadrapp_mobile/contexts/iam/application/usecases/request_otp.dart';
import 'package:quadrapp_mobile/contexts/iam/application/usecases/restore_session.dart';
import 'package:quadrapp_mobile/contexts/iam/application/usecases/sign_in_with_otp.dart';
import 'package:quadrapp_mobile/contexts/iam/application/usecases/sign_out_usecases.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/user_role.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/mappers/iam_mapper.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/repositories/auth_repository_impl.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/repositories/in_memory_access_token_holder.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/repositories/session_store_impl.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/repositories/stream_session_events.dart';
import 'package:quadrapp_mobile/contexts/notifications/application/usecases/activate_device_notifications.dart';
import 'package:quadrapp_mobile/contexts/notifications/application/usecases/create_alert_subscription.dart';
import 'package:quadrapp_mobile/contexts/notifications/application/usecases/device_token_usecases.dart';
import 'package:quadrapp_mobile/contexts/notifications/application/usecases/pending_token_removal_usecases.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/entities/device_token_removal.dart';
import 'package:quadrapp_mobile/contexts/notifications/infrastructure/mappers/notifications_mapper.dart';
import 'package:quadrapp_mobile/contexts/notifications/infrastructure/repositories/notification_repositories.dart';
import 'package:quadrapp_mobile/contexts/notifications/infrastructure/repositories/pending_push_token_removal_store_impl.dart';
import 'package:quadrapp_mobile/contexts/notifications/infrastructure/repositories/registered_push_token_store_impl.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/application/usecases/select_lot.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/repositories/selected_lot_store_impl.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/session/key_value_resettable.dart';
import 'package:quadrapp_mobile/core/session/resettable.dart';
import 'package:quadrapp_mobile/core/storage/key_value_store.dart';
import 'package:quadrapp_mobile/core/storage/secure_store.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

import '../../contexts/notifications/support.dart' as notif;
import '../../helpers/fake_clock.dart';
import '../../helpers/recording_logger.dart';
import '../../helpers/test_seed.dart';

/// Los casos de uso reales de `iam`, `notifications` y `sign_out` sobre los
/// mocks de [MockWorld].
class Suite {
  Suite(this.world) {
    final iamMapper = IamMapper(logger);
    final auth = AuthRepositoryImpl(
      remote: MockAuthRemoteDataSource(world),
      mapper: iamMapper,
      clock: world.clock,
    );
    sessions = SessionStoreImpl(
      values: values,
      secrets: secrets,
      mapper: iamMapper,
    );
    expire = ExpireSession(
      sessions: sessions,
      accessToken: accessHolder,
      events: events,
    );
    requestOtp = RequestOtp(auth);
    signIn = SignInWithOtp(
      auth: auth,
      sessions: sessions,
      accessToken: accessHolder,
    );
    restore = RestoreSession(sessions);
    refresh = RefreshSession(
      auth: auth,
      sessions: sessions,
      accessToken: accessHolder,
      expire: expire,
    );

    final notificationsMapper = NotificationsMapper(logger);
    final devices = DeviceTokenRepositoryImpl(
      MockDeviceTokenRemoteDataSource(world),
    );
    gateway = StubPushGateway(world.controls, logger);
    final activate = ActivateDeviceNotifications(
      gateway: gateway,
      devices: devices,
      tokenStore: registeredToken,
      pendingRemovals: pendingRemoval,
    );
    createSubscription = CreateAlertSubscription(
      subscriptions: AlertSubscriptionRepositoryImpl(
        remote: MockAlertSubscriptionRemoteDataSource(world),
        mapper: notificationsMapper,
      ),
      activateDevice: activate,
    );
    retryRemoval = RetryPendingTokenRemoval(
      devices: devices,
      pendingRemovals: pendingRemoval,
    );
    selectLot = SelectLot(SelectedLotStoreImpl(values));

    final registry = ResettableRegistry()
      ..register(KeyValueResettable(values, [StoreKeys.user, StoreKeys.cache]))
      ..register(sessions)
      ..register(accessHolder);
    signOut = SignOut(
      getPushToken: GetRegisteredPushToken(registeredToken),
      removePushToken: RemoveDeviceTokenOnSignOut(
        unregister: UnregisterDeviceToken(
          devices: devices,
          tokenStore: registeredToken,
        ),
        pendingRemovals: pendingRemoval,
      ),
      revokeSession: RevokeSession(auth: auth, sessions: sessions),
      clearSession: ClearSession(sessions: sessions, accessToken: accessHolder),
      resettables: registry,
    );
  }

  final MockWorld world;
  final RecordingLogger logger = RecordingLogger();
  final InMemoryKeyValueStore values = InMemoryKeyValueStore();
  final InMemorySecureStore secrets = InMemorySecureStore();
  final InMemoryAccessTokenHolder accessHolder = InMemoryAccessTokenHolder();
  final StreamSessionEvents events = StreamSessionEvents();
  late final RegisteredPushTokenStoreImpl registeredToken =
      RegisteredPushTokenStoreImpl(values);
  late final PendingPushTokenRemovalStoreImpl pendingRemoval =
      PendingPushTokenRemovalStoreImpl(values);
  late final SessionStoreImpl sessions;
  late final ExpireSession expire;
  late final RequestOtp requestOtp;
  late final SignInWithOtp signIn;
  late final RestoreSession restore;
  late final RefreshSession refresh;
  late final StubPushGateway gateway;
  late final CreateAlertSubscription createSubscription;
  late final RetryPendingTokenRemoval retryRemoval;
  late final SelectLot selectLot;
  late final SignOut signOut;

  Future<void> login([String email = 'conductor@upc.edu.pe']) async {
    await requestOtp(email);
    await signIn(SignInWithOtpParams(email: email, code: '123456'));
  }
}

CreateAlertSubscriptionParams subscriptionFor(LotId lot) =>
    CreateAlertSubscriptionParams(
      lotId: lot,
      days: const {1, 3},
      from: notif.time(7, 30),
      to: notif.time(9, 0),
    );

Suite newSuite({MockControls? controls, FakeClock? clock}) => Suite(
  MockWorld(
    seed: testSeed,
    clock: clock ?? FakeClock(),
    controls: controls,
    random: Random(1),
    latency: false,
  ),
);

void main() {
  group('mocks de iam: pedir el código', () {
    test(
      'un correo de upc.edu.pe recibe el código con su vigencia (202)',
      () async {
        final suite = newSuite();

        final result = await suite.requestOtp('conductor@upc.edu.pe');

        expect(result.valueOrNull?.expiresIn, MockIamState.otpValidity);
      },
    );

    test('un correo de otra institución da 403', () async {
      final suite = newSuite();

      final result = await suite.requestOtp('alguien@gmail.com');

      expect(result.failureOrNull, isA<ForbiddenFailure>());
    });

    test('el interruptor 429 da la cuenta regresiva (retryAfter)', () async {
      final controls = MockControls()..force429 = true;
      final suite = newSuite(controls: controls);

      final result = await suite.requestOtp('conductor@upc.edu.pe');

      expect(
        (result.failureOrNull! as RateLimitedFailure).retryAfter,
        const Duration(seconds: MockIamState.retryAfterSec),
      );
    });
  });

  group('mocks de iam: iniciar sesión', () {
    test('conductor@upc.edu.pe con 123456 inicia sesión como DRIVER', () async {
      final suite = newSuite();
      await suite.requestOtp('conductor@upc.edu.pe');

      final result = await suite.signIn(
        const SignInWithOtpParams(
          email: 'conductor@upc.edu.pe',
          code: '123456',
        ),
      );

      final session = result.valueOrNull!;
      expect(session.role, UserRole.driver);
      expect(session.institution.id, const InstitutionId(1));
      expect(suite.accessHolder.current?.value, startsWith('mock-access-'));
      expect(suite.logger.messages, isEmpty);
    });

    test(
      'administrador@upc.edu.pe entra como ADMIN (id 2) y la app lo acepta',
      () async {
        final suite = newSuite();
        await suite.login('administrador@upc.edu.pe');

        final session = (await suite.restore(const NoParams())).valueOrNull!;
        expect(session.role, UserRole.admin);
        expect(session.userId, const UserId(2));
      },
    );

    test('código incorrecto, sin pedir o ya usado da 401', () async {
      final suite = newSuite();

      const params = SignInWithOtpParams(
        email: 'conductor@upc.edu.pe',
        code: '123456',
      );
      // Sin haber pedido un código.
      expect(
        (await suite.signIn(params)).failureOrNull,
        isA<UnauthorizedFailure>(),
      );

      await suite.requestOtp('conductor@upc.edu.pe');
      expect(
        (await suite.signIn(
          const SignInWithOtpParams(
            email: 'conductor@upc.edu.pe',
            code: '000000',
          ),
        )).failureOrNull,
        isA<UnauthorizedFailure>(),
      );
      // Es de un solo uso.
      expect((await suite.signIn(params)).isSuccess, isTrue);
      expect(
        (await suite.signIn(params)).failureOrNull,
        isA<UnauthorizedFailure>(),
      );
    });

    test('un código vencido da 401 (el reloj es el del servidor)', () async {
      final clock = FakeClock();
      final suite = newSuite(clock: clock);
      await suite.requestOtp('conductor@upc.edu.pe');

      clock.advance(MockIamState.otpValidity + const Duration(seconds: 1));
      final result = await suite.signIn(
        const SignInWithOtpParams(
          email: 'conductor@upc.edu.pe',
          code: '123456',
        ),
      );

      expect(result.failureOrNull, isA<UnauthorizedFailure>());
    });

    test('con 5 intentos fallidos el código deja de servir', () async {
      final suite = newSuite();
      await suite.requestOtp('conductor@upc.edu.pe');
      for (var i = 0; i < MockIamState.maxAttempts; i++) {
        await suite.signIn(
          const SignInWithOtpParams(
            email: 'conductor@upc.edu.pe',
            code: '111111',
          ),
        );
      }

      final result = await suite.signIn(
        const SignInWithOtpParams(
          email: 'conductor@upc.edu.pe',
          code: '123456',
        ),
      );

      expect(result.failureOrNull, isA<UnauthorizedFailure>());
    });
  });

  group('mocks de iam: renovar y expirar la sesión', () {
    test(
      'el refresh devuelve un access token nuevo y el refresh no rota',
      () async {
        final suite = newSuite();
        await suite.login();
        final before = suite.accessHolder.current;

        final result = await suite.refresh(const NoParams());

        expect(result.isSuccess, isTrue);
        expect(suite.accessHolder.current, isNot(before));
        expect(
          (await suite.sessions.read())?.refreshToken.value,
          startsWith('mock-refresh-'),
        );
      },
    );

    test(
      'el interruptor de sesión expirada: el refresh da 401 y la sesión expira',
      () async {
        final suite = newSuite();
        await suite.login();
        suite.world.controls.sessionExpired = true;
        var notified = 0;
        final subscription = suite.events.expired.listen((_) => notified++);

        final result = await suite.refresh(const NoParams());
        await Future<void>.delayed(Duration.zero);
        await subscription.cancel();

        expect(result.failureOrNull, isA<UnauthorizedFailure>());
        expect(await suite.sessions.read(), isNull);
        expect(notified, 1);
      },
    );

    test('un error de red forzado no expira la sesión', () async {
      final suite = newSuite();
      await suite.login();
      suite.world.controls.forceNetworkError = true;

      final result = await suite.refresh(const NoParams());

      expect(result.failureOrNull, isA<NetworkFailure>());
      expect(await suite.sessions.read(), isNotNull);
    });
  });

  group('coherencia entre contextos (solo por identificadores)', () {
    test(
      'cerrar sesión: revoca la sesión, da de baja el token y limpia todo',
      () async {
        final suite = newSuite();
        await suite.login();
        // El conductor elige un lote de parking_configuration y se suscribe a
        // una franja: se registra el token push.
        final lots = await MockParkingLotRemoteDataSource(suite.world).list();
        final lotId = LotId(lots.first.id);
        await suite.selectLot(lotId);
        final created = (await suite.createSubscription(
          subscriptionFor(lotId),
        )).valueOrNull!;
        expect(created.subscription.lotId, lotId);
        expect(suite.world.notifications.deviceTokens, {
          StubPushGateway.mockToken,
        });
        expect(suite.world.iam.refreshTokens, hasLength(1));
        await suite.values.setString('device.language', 'es');
        await suite.values.setString('cache.layout.${lotId.value}', '{}');

        final report = (await suite.signOut(
          const SignOutParams(),
        )).valueOrNull!;

        expect(report.pushToken, DeviceTokenRemoval.removed);
        expect(report.sessionRevoked, isTrue);
        // El "servidor" ya no tiene ni la sesión ni el token.
        expect(suite.world.iam.refreshTokens, isEmpty);
        expect(suite.world.notifications.deviceTokens, isEmpty);
        // Y el dispositivo quedó limpio, salvo el idioma.
        expect(
          await suite.restore(const NoParams()).then((r) => r.valueOrNull),
          isNull,
        );
        expect(await suite.values.getString('user.selectedLot'), isNull);
        expect(
          await suite.values.getString('cache.layout.${lotId.value}'),
          isNull,
        );
        expect(await suite.values.getString('device.language'), 'es');
      },
    );

    test(
      'sin red: limpia igual y la baja pendiente se completa al volver',
      () async {
        final suite = newSuite();
        await suite.login();
        await suite.createSubscription(
          subscriptionFor(const LotId(1)),
        );
        suite.world.controls.forceNetworkError = true;

        final report = (await suite.signOut(
          const SignOutParams(),
        )).valueOrNull!;

        expect(report.pushToken, DeviceTokenRemoval.pending);
        expect(report.sessionRevoked, isFalse);
        expect(
          await suite.restore(const NoParams()).then((r) => r.valueOrNull),
          isNull,
        );
        // El servidor aún tiene el token y la sesión (no hubo red).
        expect(suite.world.notifications.deviceTokens, isNotEmpty);
        expect(await suite.pendingRemoval.read(), isNotNull);

        // Vuelve la red: el reintento lo completa sin sesión.
        suite.world.controls.forceNetworkError = false;
        final retried = await suite.retryRemoval(const NoParams());

        expect(retried.valueOrNull, DeviceTokenRemoval.removed);
        expect(suite.world.notifications.deviceTokens, isEmpty);
        expect(await suite.pendingRemoval.read(), isNull);
      },
    );

    test(
      'sesión expirada: se limpia sin llamar a /auth/logout y el token sí se da de baja',
      () async {
        final suite = newSuite();
        await suite.login();
        await suite.createSubscription(
          subscriptionFor(const LotId(1)),
        );
        suite.world.controls.sessionExpired = true;
        await suite.refresh(const NoParams());

        final report = (await suite.signOut(
          const SignOutParams(reason: SignOutReason.sessionExpired),
        )).valueOrNull!;

        expect(report.sessionRevoked, isFalse);
        expect(report.pushToken, DeviceTokenRemoval.removed);
        expect(suite.world.notifications.deviceTokens, isEmpty);
      },
    );

    test('el id de la institución de la sesión es único y estable', () async {
      final suite = newSuite();
      await suite.login();

      final session = (await suite.restore(const NoParams())).valueOrNull!;

      expect(session.institution.id.value, suite.world.iam.institutionId);
      expect(session.userId, const UserId(1));
    });
  });
}

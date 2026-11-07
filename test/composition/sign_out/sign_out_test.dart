import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/composition/sign_out/sign_out.dart';
import 'package:quadrapp_mobile/contexts/iam/application/usecases/sign_out_usecases.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/entities/login_grant.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/entities/otp_challenge.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/repositories/auth_repository.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/access_token.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/email_address.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/otp_code.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/refresh_token.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/mappers/iam_mapper.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/repositories/in_memory_access_token_holder.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/repositories/session_store_impl.dart';
import 'package:quadrapp_mobile/contexts/notifications/application/usecases/device_token_usecases.dart';
import 'package:quadrapp_mobile/contexts/notifications/application/usecases/pending_token_removal_usecases.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/entities/device_token_removal.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/repositories/device_token_repository.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/value_objects/push_token.dart';
import 'package:quadrapp_mobile/contexts/notifications/infrastructure/repositories/pending_push_token_removal_store_impl.dart';
import 'package:quadrapp_mobile/contexts/notifications/infrastructure/repositories/registered_push_token_store_impl.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/session/key_value_resettable.dart';
import 'package:quadrapp_mobile/core/session/resettable.dart';
import 'package:quadrapp_mobile/core/storage/key_value_store.dart';
import 'package:quadrapp_mobile/core/storage/secure_store.dart';

import '../../contexts/iam/support.dart';
import '../../contexts/notifications/support.dart' as notifications;
import '../../helpers/recording_logger.dart';

/// El servidor de autenticación: guarda el orden de las llamadas.
class _FakeAuth implements AuthRepository {
  _FakeAuth(this.calls);

  final List<String> calls;
  Result<void> logoutResult = const Success<void>(null);

  @override
  Future<Result<void>> logout(RefreshToken refreshToken) async {
    calls.add('POST /auth/logout');
    return logoutResult;
  }

  @override
  Future<Result<OtpChallenge>> requestOtp(EmailAddress email) =>
      throw UnimplementedError();

  @override
  Future<Result<LoginGrant>> login(EmailAddress email, OtpCode code) =>
      throw UnimplementedError();

  @override
  Future<Result<AccessToken>> refresh(RefreshToken refreshToken) =>
      throw UnimplementedError();
}

/// El servidor de tokens push: guarda el orden de las llamadas.
class _FakeDevices implements DeviceTokenRepository {
  _FakeDevices(this.calls);

  final List<String> calls;
  Result<void> unregisterResult = const Success<void>(null);
  bool throwOnUnregister = false;
  PushToken? unregistered;

  @override
  Future<Result<void>> unregister(PushToken token) async {
    calls.add('POST /device-tokens/unregister');
    if (throwOnUnregister) throw StateError('bug inesperado');
    unregistered = token;
    return unregisterResult;
  }

  @override
  Future<Result<void>> register(PushToken token) => throw UnimplementedError();
}

void main() {
  late List<String> calls;
  late InMemoryKeyValueStore values;
  late InMemorySecureStore secrets;
  late SessionStoreImpl sessions;
  late InMemoryAccessTokenHolder accessHolder;
  late _FakeAuth auth;
  late _FakeDevices devices;
  late RegisteredPushTokenStoreImpl registeredToken;
  late PendingPushTokenRemovalStoreImpl pendingRemoval;
  late SignOut signOut;

  /// Los datos de un usuario con la sesión iniciada, más lo que debe
  /// sobrevivir.
  Future<void> seedDevice() async {
    await sessions.save(sampleStored());
    accessHolder.replace(accessToken());
    await registeredToken.save(notifications.pushToken('fcm:mio'));
    await values.setString('user.selectedLot', '2');
    await values.setString('cache.layout.1', '{"zones":[]}');
    await values.setString('cache.occupancy.1', '{"free":3}');
    await values.setString('device.language', 'es');
  }

  setUp(() {
    calls = [];
    values = InMemoryKeyValueStore();
    secrets = InMemorySecureStore();
    sessions = SessionStoreImpl(
      values: values,
      secrets: secrets,
      mapper: IamMapper(RecordingLogger()),
    );
    accessHolder = InMemoryAccessTokenHolder();
    auth = _FakeAuth(calls);
    devices = _FakeDevices(calls);
    registeredToken = RegisteredPushTokenStoreImpl(values);
    pendingRemoval = PendingPushTokenRemovalStoreImpl(values);

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
  });

  group('SignOut (US02)', () {
    test('orden: baja del token push, revocación y limpieza local', () async {
      await seedDevice();

      final report = (await signOut(const SignOutParams())).valueOrNull!;

      expect(calls, ['POST /device-tokens/unregister', 'POST /auth/logout']);
      // Leyó el token ANTES de limpiar: la baja usó el que estaba guardado.
      expect(devices.unregistered, notifications.pushToken('fcm:mio'));
      expect(report.pushToken, DeviceTokenRemoval.removed);
      expect(report.sessionRevoked, isTrue);
    });

    test(
      'borra tokens, cachés, estacionamiento y estado; conserva SOLO el idioma',
      () async {
        await seedDevice();

        await signOut(const SignOutParams());

        expect(await sessions.read(), isNull);
        expect(await secrets.read('refreshToken'), isNull);
        expect(accessHolder.current, isNull);
        expect(await values.getString('user.selectedLot'), isNull);
        expect(await values.getString('cache.layout.1'), isNull);
        expect(await values.getString('cache.occupancy.1'), isNull);
        expect(await registeredToken.read(), isNull);
        // Lo único que queda es el idioma.
        expect(await values.getString('device.language'), 'es');
      },
    );

    test(
      'sin red: limpia en local igual y deja SOLO el token como baja pendiente',
      () async {
        await seedDevice();
        devices.unregisterResult = const Err(NetworkFailure());
        auth.logoutResult = const Err(NetworkFailure());

        final result = await signOut(const SignOutParams());

        final report = result.valueOrNull!;
        expect(report.pushToken, DeviceTokenRemoval.pending);
        expect(report.sessionRevoked, isFalse);
        // Limpieza local completa: ni refresh token ni sesión.
        expect(await sessions.read(), isNull);
        expect(await secrets.read('refreshToken'), isNull);
        expect(await values.getString('user.selectedLot'), isNull);
        expect(await values.getString('cache.layout.1'), isNull);
        // La baja pendiente sobrevive y contiene solo el token push.
        expect(await pendingRemoval.read(), notifications.pushToken('fcm:mio'));
        expect(
          await values.getString(PendingPushTokenRemovalStoreImpl.key),
          'fcm:mio',
        );
        expect(await values.getString('device.language'), 'es');
      },
    );

    test('lo único que sobrevive son el idioma y la baja pendiente', () async {
      await seedDevice();
      devices.unregisterResult = const Err(NetworkFailure());

      await signOut(const SignOutParams());

      final survivors = <String>[
        for (final key in [
          'user.selectedLot',
          'user.session',
          'user.pushToken',
          'cache.layout.1',
          'cache.occupancy.1',
          'device.language',
          PendingPushTokenRemovalStoreImpl.key,
        ])
          if (await values.getString(key) != null) key,
      ];
      expect(survivors, [
        'device.language',
        'device.pendingPushTokenRemoval',
      ]);
    });

    test(
      'sesión expirada: no llama a /auth/logout, sí limpia y da de baja el token',
      () async {
        await seedDevice();

        final report = (await signOut(
          const SignOutParams(reason: SignOutReason.sessionExpired),
        )).valueOrNull!;

        expect(calls, ['POST /device-tokens/unregister']);
        expect(report.sessionRevoked, isFalse);
        expect(report.pushToken, DeviceTokenRemoval.removed);
        expect(await sessions.read(), isNull);
      },
    );

    test('un 5xx en la baja también queda pendiente', () async {
      await seedDevice();
      devices.unregisterResult = const Err(ServerFailure('boom', 503));

      final report = (await signOut(const SignOutParams())).valueOrNull!;

      expect(report.pushToken, DeviceTokenRemoval.pending);
      expect(await pendingRemoval.read(), isNotNull);
    });

    test('sin token push registrado solo revoca y limpia', () async {
      await sessions.save(sampleStored());
      accessHolder.replace(accessToken());

      final report = (await signOut(const SignOutParams())).valueOrNull!;

      expect(calls, ['POST /auth/logout']);
      expect(report.pushToken, DeviceTokenRemoval.nothingToRemove);
      expect(await pendingRemoval.read(), isNull);
    });

    test(
      'limpia el dispositivo aunque un paso falle de forma inesperada',
      () async {
        await seedDevice();
        devices.throwOnUnregister = true;

        await expectLater(signOut(const SignOutParams()), throwsStateError);

        expect(await sessions.read(), isNull);
        expect(await secrets.read('refreshToken'), isNull);
        expect(await values.getString('user.selectedLot'), isNull);
        expect(accessHolder.current, isNull);
      },
    );

    test(
      'un cierre en curso se comparte: no repite la baja ni el logout',
      () async {
        await seedDevice();

        final results = await Future.wait([
          signOut(const SignOutParams()),
          signOut(const SignOutParams(reason: SignOutReason.sessionExpired)),
        ]);

        expect(calls, ['POST /device-tokens/unregister', 'POST /auth/logout']);
        expect(results[1], same(results[0]));
        // Terminado el primero, el siguiente cierre vuelve a ejecutarse.
        await seedDevice();
        calls.clear();
        await signOut(const SignOutParams());
        expect(calls, ['POST /device-tokens/unregister', 'POST /auth/logout']);
      },
    );
  });
}

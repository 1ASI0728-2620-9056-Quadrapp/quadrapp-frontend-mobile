import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quadrapp_mobile/contexts/notifications/application/usecases/activate_device_notifications.dart';
import 'package:quadrapp_mobile/contexts/notifications/application/usecases/device_token_usecases.dart';
import 'package:quadrapp_mobile/contexts/notifications/application/usecases/pending_token_removal_usecases.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/entities/device_activation.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/entities/device_token_removal.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/repositories/device_token_repository.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/repositories/push_gateway.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/repositories/registered_push_token_store.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/value_objects/push_permission_status.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/value_objects/push_token.dart';
import 'package:quadrapp_mobile/contexts/notifications/infrastructure/repositories/pending_push_token_removal_store_impl.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/storage/key_value_store.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

import 'support.dart';

class _MockDevices extends Mock implements DeviceTokenRepository {}

class _MockGateway extends Mock implements PushGateway {}

class _FakeToken extends Fake implements PushToken {}

class _MemoryTokenStore implements RegisteredPushTokenStore {
  PushToken? stored;

  @override
  Future<PushToken?> read() async => stored;

  @override
  Future<void> save(PushToken token) async => stored = token;

  @override
  Future<void> clear() async => stored = null;
}

void main() {
  setUpAll(() => registerFallbackValue(_FakeToken()));

  late _MockDevices devices;
  late MemoryPendingRemovalStore pending;
  late _MemoryTokenStore registered;

  setUp(() {
    devices = _MockDevices();
    pending = MemoryPendingRemovalStore();
    registered = _MemoryTokenStore();
  });

  void unregisterReturns(Result<void> result) =>
      when(() => devices.unregister(any())).thenAnswer((_) async => result);

  RemoveDeviceTokenOnSignOut removeOnSignOut() => RemoveDeviceTokenOnSignOut(
    unregister: UnregisterDeviceToken(devices: devices, tokenStore: registered),
    pendingRemovals: pending,
  );

  RetryPendingTokenRemoval retry() =>
      RetryPendingTokenRemoval(devices: devices, pendingRemovals: pending);

  group('baja del token al cerrar sesión', () {
    test('con servidor: se da de baja y no queda nada pendiente', () async {
      registered.stored = pushToken();
      unregisterReturns(const Success<void>(null));

      final result = await removeOnSignOut()(
        RemoveDeviceTokenOnSignOutParams(token: pushToken()),
      );

      expect(result.valueOrNull, DeviceTokenRemoval.removed);
      expect(pending.pending, isNull);
      expect(registered.stored, isNull);
    });

    test('sin red o 5xx: guarda SOLO ese token como baja pendiente', () async {
      for (final failure in [
        const NetworkFailure(),
        const ServerFailure('boom', 503),
        const RateLimitedFailure(),
      ]) {
        pending.pending = null;
        unregisterReturns(Err(failure));

        final result = await removeOnSignOut()(
          RemoveDeviceTokenOnSignOutParams(token: pushToken('t-1')),
        );

        expect(result.valueOrNull, DeviceTokenRemoval.pending);
        expect(pending.pending, pushToken('t-1'), reason: '$failure');
      }
    });

    test(
      'un error que reintentar no arregla se descarta, no se guarda',
      () async {
        unregisterReturns(const Err(ValidationFailure('token inválido')));

        final result = await removeOnSignOut()(
          RemoveDeviceTokenOnSignOutParams(token: pushToken()),
        );

        expect(result.valueOrNull, DeviceTokenRemoval.abandoned);
        expect(pending.pending, isNull);
      },
    );

    test('sin token registrado no hay nada que hacer', () async {
      final result = await removeOnSignOut()(
        const RemoveDeviceTokenOnSignOutParams(),
      );

      expect(result.valueOrNull, DeviceTokenRemoval.nothingToRemove);
      verifyNever(() => devices.unregister(any()));
    });
  });

  group('reintento de la baja pendiente (arranque y primer plano)', () {
    test('sin baja pendiente no llama al servidor', () async {
      final result = await retry()(const NoParams());

      expect(result.valueOrNull, DeviceTokenRemoval.nothingToRemove);
      verifyNever(() => devices.unregister(any()));
    });

    test('al lograrlo se borra el registro', () async {
      pending.pending = pushToken('t-1');
      unregisterReturns(const Success<void>(null));

      final result = await retry()(const NoParams());

      expect(result.valueOrNull, DeviceTokenRemoval.removed);
      expect(pending.pending, isNull);
      verify(() => devices.unregister(pushToken('t-1'))).called(1);
    });

    test(
      'ante un 404 también se borra (el repositorio lo trata como éxito)',
      () async {
        // `DeviceTokenRepositoryImpl` convierte el 404 en Success; aquí se
        // comprueba que el caso de uso lo trata como baja lograda.
        pending.pending = pushToken('t-1');
        unregisterReturns(const Success<void>(null));

        await retry()(const NoParams());

        expect(pending.pending, isNull);
      },
    );

    test(
      'ante un fallo de red o un 5xx se conserva para el próximo intento',
      () async {
        pending.pending = pushToken('t-1');
        for (final failure in [
          const NetworkFailure(),
          const ServerFailure('boom', 500),
        ]) {
          unregisterReturns(Err(failure));

          final result = await retry()(const NoParams());

          expect(result.valueOrNull, DeviceTokenRemoval.pending);
          expect(pending.pending, pushToken('t-1'), reason: '$failure');
        }
      },
    );

    test(
      'un error que no se arregla reintentando descarta el registro',
      () async {
        pending.pending = pushToken('t-1');
        unregisterReturns(const Err(ValidationFailure()));

        final result = await retry()(const NoParams());

        expect(result.valueOrNull, DeviceTokenRemoval.abandoned);
        expect(pending.pending, isNull);
      },
    );

    test('el registro vive bajo device. y contiene solo el token', () async {
      final keyValues = InMemoryKeyValueStore();
      final store = PendingPushTokenRemovalStoreImpl(keyValues);

      await store.save(pushToken('solo-el-token'));

      expect(
        PendingPushTokenRemovalStoreImpl.key,
        'device.pendingPushTokenRemoval',
      );
      expect(
        await keyValues.getString(PendingPushTokenRemovalStoreImpl.key),
        'solo-el-token',
      );
      // Sobrevive al borrado de los datos de usuario y de caché.
      await keyValues.removeByPrefix(StoreKeys.user);
      await keyValues.removeByPrefix(StoreKeys.cache);
      expect(await store.read(), pushToken('solo-el-token'));
    });
  });

  group('descartar la baja pendiente al reregistrar el mismo token', () {
    late _MockGateway gateway;
    late ActivateDeviceNotifications activate;

    setUp(() {
      gateway = _MockGateway();
      activate = ActivateDeviceNotifications(
        gateway: gateway,
        devices: devices,
        tokenStore: registered,
        pendingRemovals: pending,
      );
      when(
        () => gateway.permissionStatus(),
      ).thenAnswer((_) async => PushPermissionStatus.granted);
      when(
        () => devices.register(any()),
      ).thenAnswer((_) async => const Success<void>(null));
    });

    test('mismo token: la baja pendiente se descarta', () async {
      // Otro usuario inicia sesión en el teléfono; FCM entrega el mismo token.
      pending.pending = pushToken('mismo');
      when(() => gateway.token()).thenAnswer((_) async => pushToken('mismo'));

      final result = await activate(const NoParams());

      expect(result.valueOrNull, DeviceActivation.registered);
      expect(pending.pending, isNull);
      expect(registered.stored, pushToken('mismo'));
    });

    test('otro token: la baja pendiente se conserva', () async {
      pending.pending = pushToken('viejo');
      when(() => gateway.token()).thenAnswer((_) async => pushToken('nuevo'));

      await activate(const NoParams());

      expect(pending.pending, pushToken('viejo'));
    });

    test('si el registro falla, la baja pendiente no se toca', () async {
      pending.pending = pushToken('mismo');
      when(() => gateway.token()).thenAnswer((_) async => pushToken('mismo'));
      when(
        () => devices.register(any()),
      ).thenAnswer((_) async => const Err(NetworkFailure()));

      final result = await activate(const NoParams());

      expect(result.isFailure, isTrue);
      expect(pending.pending, pushToken('mismo'));
    });
  });
}

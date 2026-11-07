import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quadrapp_mobile/contexts/notifications/application/usecases/activate_device_notifications.dart';
import 'package:quadrapp_mobile/contexts/notifications/application/usecases/create_alert_subscription.dart';
import 'package:quadrapp_mobile/contexts/notifications/application/usecases/device_token_usecases.dart';
import 'package:quadrapp_mobile/contexts/notifications/application/usecases/list_alert_subscriptions.dart';
import 'package:quadrapp_mobile/contexts/notifications/application/usecases/notification_preferences_usecases.dart';
import 'package:quadrapp_mobile/contexts/notifications/application/usecases/remove_alert_subscription.dart';
import 'package:quadrapp_mobile/contexts/notifications/application/usecases/set_alert_subscription_active.dart';
import 'package:quadrapp_mobile/contexts/notifications/application/usecases/watch_push_messages.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/entities/alert_subscription.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/entities/device_activation.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/entities/notification_preferences.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/entities/push_message.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/repositories/alert_subscription_repository.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/repositories/device_token_repository.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/repositories/notification_preferences_repository.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/repositories/push_gateway.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/repositories/registered_push_token_store.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/value_objects/alert_language.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/value_objects/push_permission_status.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/value_objects/push_token.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

import 'support.dart';

class _MockGateway extends Mock implements PushGateway {}

class _MockDevices extends Mock implements DeviceTokenRepository {}

class _MockSubscriptions extends Mock implements AlertSubscriptionRepository {}

class _MockPreferences extends Mock
    implements NotificationPreferencesRepository {}

/// Un almacén en memoria del token registrado.
class _MemoryTokenStore implements RegisteredPushTokenStore {
  PushToken? stored;

  @override
  Future<PushToken?> read() async => stored;

  @override
  Future<void> save(PushToken token) async => stored = token;

  @override
  Future<void> clear() async => stored = null;
}

/// Un servidor en memoria: sirve para comprobar que dar de baja una
/// suscripción conserva las demás.
class _InMemorySubscriptions implements AlertSubscriptionRepository {
  final List<AlertSubscription> items = [];
  int _nextId = 1;

  @override
  Future<Result<List<AlertSubscription>>> list() async =>
      Success(List.of(items));

  @override
  Future<Result<AlertSubscription>> create(AlertSubscriptionDraft draft) async {
    final created = AlertSubscription(
      id: AlertSubscriptionId(_nextId++),
      lotId: draft.lotId,
      days: draft.days,
      slot: draft.slot,
    );
    items.add(created);
    return Success(created);
  }

  @override
  Future<Result<AlertSubscription>> setActive(
    AlertSubscriptionId id, {
    required bool active,
  }) async {
    final index = items.indexWhere((s) => s.id == id);
    if (index < 0) return const Err(NotFoundFailure());
    return Success(items[index] = items[index].copyWith(active: active));
  }

  @override
  Future<Result<void>> remove(AlertSubscriptionId id) async {
    items.removeWhere((s) => s.id == id);
    return const Success<void>(null);
  }
}

class _FakeToken extends Fake implements PushToken {}

class _FakeDraft extends Fake implements AlertSubscriptionDraft {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeToken());
    registerFallbackValue(_FakeDraft());
    registerFallbackValue(samplePreferences);
  });

  late _MockGateway gateway;
  late _MockDevices devices;
  late _MemoryTokenStore tokenStore;
  late MemoryPendingRemovalStore pendingRemovals;
  late ActivateDeviceNotifications activate;

  setUp(() {
    gateway = _MockGateway();
    devices = _MockDevices();
    tokenStore = _MemoryTokenStore();
    pendingRemovals = MemoryPendingRemovalStore();
    activate = ActivateDeviceNotifications(
      gateway: gateway,
      devices: devices,
      tokenStore: tokenStore,
      pendingRemovals: pendingRemovals,
    );
    when(
      () => devices.register(any()),
    ).thenAnswer((_) async => const Success<void>(null));
  });

  void givenToken([PushToken? token]) =>
      when(() => gateway.token()).thenAnswer((_) async => token ?? pushToken());

  group('ActivateDeviceNotifications (US33 esc. 2)', () {
    test('permiso concedido: registra el token y lo guarda', () async {
      when(
        () => gateway.permissionStatus(),
      ).thenAnswer((_) async => PushPermissionStatus.granted);
      givenToken();

      final result = await activate(const NoParams());

      expect(result.valueOrNull, DeviceActivation.registered);
      verify(() => devices.register(pushToken())).called(1);
      expect(tokenStore.stored, pushToken());
      // Con el permiso ya concedido no se vuelve a pedir.
      verifyNever(() => gateway.requestPermission());
    });

    test(
      'permiso pendiente: lo pide una vez, con contexto, y registra',
      () async {
        when(
          () => gateway.permissionStatus(),
        ).thenAnswer((_) async => PushPermissionStatus.denied);
        when(
          () => gateway.requestPermission(),
        ).thenAnswer((_) async => PushPermissionStatus.granted);
        givenToken();

        final result = await activate(const NoParams());

        expect(result.valueOrNull, DeviceActivation.registered);
        verify(() => gateway.requestPermission()).called(1);
      },
    );

    test('permiso negado: no es un error y no hay token ni registro', () async {
      when(
        () => gateway.permissionStatus(),
      ).thenAnswer((_) async => PushPermissionStatus.denied);
      when(
        () => gateway.requestPermission(),
      ).thenAnswer((_) async => PushPermissionStatus.denied);

      final result = await activate(const NoParams());

      expect(result.valueOrNull, DeviceActivation.permissionDenied);
      verifyNever(() => gateway.token());
      verifyNever(() => devices.register(any()));
      expect(tokenStore.stored, isNull);
    });

    test('permiso bloqueado: no vuelve a pedirlo', () async {
      when(
        () => gateway.permissionStatus(),
      ).thenAnswer((_) async => PushPermissionStatus.deniedForever);

      final result = await activate(const NoParams());

      expect(result.valueOrNull, DeviceActivation.permissionBlocked);
      verifyNever(() => gateway.requestPermission());
    });

    test(
      'permiso bloqueado tras pedirlo: se explica que hay que ir a ajustes',
      () async {
        when(
          () => gateway.permissionStatus(),
        ).thenAnswer((_) async => PushPermissionStatus.denied);
        when(
          () => gateway.requestPermission(),
        ).thenAnswer((_) async => PushPermissionStatus.deniedForever);

        expect(
          (await activate(const NoParams())).valueOrNull,
          DeviceActivation.permissionBlocked,
        );
      },
    );

    test('sin token del proveedor: queda sin habilitar', () async {
      when(
        () => gateway.permissionStatus(),
      ).thenAnswer((_) async => PushPermissionStatus.granted);
      when(() => gateway.token()).thenAnswer((_) async => null);

      final result = await activate(const NoParams());

      expect(result.valueOrNull, DeviceActivation.tokenUnavailable);
      verifyNever(() => devices.register(any()));
    });

    test('un token ya registrado no se vuelve a enviar', () async {
      when(
        () => gateway.permissionStatus(),
      ).thenAnswer((_) async => PushPermissionStatus.granted);
      givenToken();
      tokenStore.stored = pushToken();

      final result = await activate(const NoParams());

      expect(result.valueOrNull, DeviceActivation.registered);
      verifyNever(() => devices.register(any()));
    });

    test('si el servidor falla, es un Err y el token no se guarda', () async {
      when(
        () => gateway.permissionStatus(),
      ).thenAnswer((_) async => PushPermissionStatus.granted);
      givenToken();
      when(
        () => devices.register(any()),
      ).thenAnswer((_) async => const Err(NetworkFailure()));

      final result = await activate(const NoParams());

      expect(result.failureOrNull, isA<NetworkFailure>());
      expect(tokenStore.stored, isNull);
    });

    test('una excepción de la plataforma no cruza la capa', () async {
      when(
        () => gateway.permissionStatus(),
      ).thenThrow(StateError('plataforma'));

      final result = await activate(const NoParams());

      expect(result.isFailure, isTrue);
    });
  });

  group('CreateAlertSubscription (US33 esc. 1 y 2)', () {
    late _MockSubscriptions subscriptions;
    late CreateAlertSubscription create;

    CreateAlertSubscriptionParams params({Set<int> days = const {1, 3}}) =>
        CreateAlertSubscriptionParams(
          lotId: lotId,
          days: days,
          from: time(7, 30),
          to: time(9, 0),
        );

    setUp(() {
      subscriptions = _MockSubscriptions();
      create = CreateAlertSubscription(
        subscriptions: subscriptions,
        activateDevice: activate,
      );
      when(
        () => subscriptions.create(any()),
      ).thenAnswer((_) async => Success(sampleSubscription()));
      when(
        () => gateway.permissionStatus(),
      ).thenAnswer((_) async => PushPermissionStatus.denied);
      when(
        () => gateway.requestPermission(),
      ).thenAnswer((_) async => PushPermissionStatus.granted);
      givenToken();
    });

    test(
      'crea la suscripción y habilita el dispositivo en ese momento',
      () async {
        final result = await create(params());

        final created = result.valueOrNull!;
        expect(created.subscription, sampleSubscription());
        expect(created.device, DeviceActivation.registered);
        // El permiso se pide aquí (al suscribirse), y solo aquí.
        verify(() => gateway.requestPermission()).called(1);
      },
    );

    test('una franja inválida no llega al servidor ni pide permiso', () async {
      final result = await create(
        CreateAlertSubscriptionParams(
          lotId: lotId,
          days: const {1},
          from: time(9, 0),
          to: time(7, 30),
        ),
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
      verifyNever(() => subscriptions.create(any()));
      verifyNever(() => gateway.requestPermission());
    });

    test('sin días no llega al servidor', () async {
      final result = await create(params(days: const {}));

      expect(result.failureOrNull, isA<ValidationFailure>());
      verifyNever(() => subscriptions.create(any()));
    });

    test(
      'si el servidor rechaza la suscripción, no se pide el permiso',
      () async {
        when(() => subscriptions.create(any())).thenAnswer(
          (_) async => const Err(
            ValidationFailure('duplicada', {
              'slot': ['duplicate'],
            }),
          ),
        );

        final result = await create(params());

        expect(result.failureOrNull, isA<ValidationFailure>());
        verifyNever(() => gateway.permissionStatus());
        verifyNever(() => gateway.requestPermission());
      },
    );

    test('permiso negado: la suscripción queda creada igual', () async {
      when(
        () => gateway.requestPermission(),
      ).thenAnswer((_) async => PushPermissionStatus.denied);

      final result = await create(params());

      expect(result.valueOrNull?.subscription, sampleSubscription());
      expect(result.valueOrNull?.device, DeviceActivation.permissionDenied);
    });

    test(
      'sin red al registrar el token: suscripción creada y reintentable',
      () async {
        when(
          () => devices.register(any()),
        ).thenAnswer((_) async => const Err(NetworkFailure()));

        final result = await create(params());

        expect(result.isSuccess, isTrue);
        expect(result.valueOrNull?.device, DeviceActivation.registrationFailed);
      },
    );
  });

  group('suscripciones: listar y dar de baja (US33 esc. 3)', () {
    test('dar de baja una conserva las demás', () async {
      final server = _InMemorySubscriptions();
      final create = CreateAlertSubscription(
        subscriptions: server,
        activateDevice: activate,
      );
      when(
        () => gateway.permissionStatus(),
      ).thenAnswer((_) async => PushPermissionStatus.granted);
      givenToken();
      final first = (await create(
        CreateAlertSubscriptionParams(
          lotId: lotId,
          days: const {1},
          from: time(7, 0),
          to: time(8, 0),
        ),
      )).valueOrNull!.subscription;
      final second = (await create(
        CreateAlertSubscriptionParams(
          lotId: const LotId(2),
          days: const {2},
          from: time(17, 0),
          to: time(18, 0),
        ),
      )).valueOrNull!.subscription;

      await RemoveAlertSubscription(server)(first.id);

      final remaining = (await ListAlertSubscriptions(server)(
        const NoParams(),
      )).valueOrNull;
      expect(remaining, [second]);
    });

    test(
      'desactivar conserva la franja y las demás no cambian (US33 esc. 3)',
      () async {
        final server = _InMemorySubscriptions();
        final create = CreateAlertSubscription(
          subscriptions: server,
          activateDevice: activate,
        );
        final first = (await create(
          CreateAlertSubscriptionParams(
            lotId: const LotId(1),
            days: const {1, 2},
            from: time(7, 30),
            to: time(9, 0),
          ),
        )).valueOrNull!.subscription;
        final second = (await create(
          CreateAlertSubscriptionParams(
            lotId: const LotId(2),
            days: const {3},
            from: time(13, 0),
            to: time(14, 30),
          ),
        )).valueOrNull!.subscription;

        final off = await SetAlertSubscriptionActive(server)(
          SetAlertSubscriptionActiveParams(id: first.id, active: false),
        );

        expect(off.valueOrNull?.active, isFalse);
        final all = (await ListAlertSubscriptions(server)(
          const NoParams(),
        )).valueOrNull!;
        // La franja desactivada sigue en la lista y la otra no cambió.
        expect(all.map((s) => s.id), [first.id, second.id]);
        expect(all.last, second);

        final on = await SetAlertSubscriptionActive(server)(
          SetAlertSubscriptionActiveParams(id: first.id, active: true),
        );
        expect(on.valueOrNull?.active, isTrue);
      },
    );

    test('sin suscripciones la lista está vacía (no es un error)', () async {
      final result = await ListAlertSubscriptions(_InMemorySubscriptions())(
        const NoParams(),
      );

      expect(result, const Success<List<AlertSubscription>>([]));
    });
  });

  group('preferencias (US24)', () {
    late _MockPreferences preferences;

    setUp(() => preferences = _MockPreferences());

    test('obtiene y guarda las preferencias', () async {
      when(
        () => preferences.get(),
      ).thenAnswer((_) async => const Success(samplePreferences));
      const changed = NotificationPreferences(
        pushEnabled: false,
        saturationAlerts: true,
        lowArrivalAlerts: false,
        staleDataAlerts: false,
        eventAlerts: true,
        language: AlertLanguage.es,
      );
      when(
        () => preferences.save(changed),
      ).thenAnswer((_) async => const Success(changed));

      expect(
        (await GetNotificationPreferences(preferences)(
          const NoParams(),
        )).valueOrNull,
        samplePreferences,
      );
      expect(
        (await SaveNotificationPreferences(preferences)(changed)).valueOrNull,
        changed,
      );
      verify(() => preferences.save(changed)).called(1);
    });

    test('un error al guardar se devuelve como Failure', () async {
      when(
        () => preferences.save(any()),
      ).thenAnswer((_) async => const Err(NetworkFailure()));

      final result = await SaveNotificationPreferences(preferences)(
        samplePreferences,
      );

      expect(result.failureOrNull, isA<NetworkFailure>());
    });
  });

  group('token del dispositivo (US02 esc. 3, sign_out)', () {
    late UnregisterDeviceToken unregister;

    setUp(() {
      unregister = UnregisterDeviceToken(
        devices: devices,
        tokenStore: tokenStore,
      );
      when(
        () => devices.unregister(any()),
      ).thenAnswer((_) async => const Success<void>(null));
    });

    test('da de baja el token registrado y lo borra del dispositivo', () async {
      tokenStore.stored = pushToken();

      final result = await unregister(const UnregisterDeviceTokenParams());

      expect(result.isSuccess, isTrue);
      verify(() => devices.unregister(pushToken())).called(1);
      expect(tokenStore.stored, isNull);
    });

    test('sin red conserva el token para reintentar', () async {
      tokenStore.stored = pushToken();
      when(
        () => devices.unregister(any()),
      ).thenAnswer((_) async => const Err(NetworkFailure()));

      final result = await unregister(const UnregisterDeviceTokenParams());

      expect(result.failureOrNull, isA<NetworkFailure>());
      expect(tokenStore.stored, pushToken());
    });

    test('sin token registrado no llama al servidor', () async {
      final result = await unregister(const UnregisterDeviceTokenParams());

      expect(result.isSuccess, isTrue);
      verifyNever(() => devices.unregister(any()));
    });

    test(
      'un token explícito (reintento tras cerrar sesión) se da de baja',
      () async {
        final result = await unregister(
          UnregisterDeviceTokenParams(token: pushToken('otro')),
        );

        expect(result.isSuccess, isTrue);
        verify(() => devices.unregister(pushToken('otro'))).called(1);
      },
    );

    test('GetRegisteredPushToken devuelve el guardado o null', () async {
      final get = GetRegisteredPushToken(tokenStore);
      expect((await get(const NoParams())).valueOrNull, isNull);

      tokenStore.stored = pushToken();
      expect((await get(const NoParams())).valueOrNull, pushToken());
    });
  });

  test('WatchPushMessages entrega los mensajes tocados', () async {
    final controller = StreamController<PushMessage>();
    when(() => gateway.openedMessages).thenAnswer((_) => controller.stream);
    const message = PushMessage(
      type: PushMessageType.saturation,
      lotId: LotId(2),
    );

    final received = WatchPushMessages(gateway)().first;
    controller.add(message);

    expect(await received, message);
    await controller.close();
  });
}

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/app/mocks/mock_controls.dart';
import 'package:quadrapp_mobile/app/mocks/mock_world.dart';
import 'package:quadrapp_mobile/app/mocks/notifications/mock_notification_datasources.dart';
import 'package:quadrapp_mobile/app/mocks/notifications/stub_push_gateway.dart';
import 'package:quadrapp_mobile/app/mocks/parking_configuration/mock_parking_configuration_datasources.dart';
import 'package:quadrapp_mobile/contexts/notifications/application/usecases/activate_device_notifications.dart';
import 'package:quadrapp_mobile/contexts/notifications/application/usecases/create_alert_subscription.dart';
import 'package:quadrapp_mobile/contexts/notifications/application/usecases/device_token_usecases.dart';
import 'package:quadrapp_mobile/contexts/notifications/application/usecases/list_alert_subscriptions.dart';
import 'package:quadrapp_mobile/contexts/notifications/application/usecases/notification_preferences_usecases.dart';
import 'package:quadrapp_mobile/contexts/notifications/application/usecases/remove_alert_subscription.dart';
import 'package:quadrapp_mobile/contexts/notifications/application/usecases/set_alert_subscription_active.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/entities/device_activation.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/entities/push_message.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/value_objects/alert_language.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/value_objects/push_permission_status.dart';
import 'package:quadrapp_mobile/contexts/notifications/infrastructure/mappers/notifications_mapper.dart';
import 'package:quadrapp_mobile/contexts/notifications/infrastructure/repositories/notification_repositories.dart';
import 'package:quadrapp_mobile/contexts/notifications/infrastructure/repositories/registered_push_token_store_impl.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/storage/key_value_store.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

import '../../contexts/notifications/support.dart';
import '../../helpers/fake_clock.dart';
import '../../helpers/recording_logger.dart';
import '../../helpers/test_seed.dart';

/// Los casos de uso reales sobre los mocks de [MockWorld] y el stub de push.
class Suite {
  Suite(this.world) {
    final mapper = NotificationsMapper(logger);
    final subscriptions = AlertSubscriptionRepositoryImpl(
      remote: MockAlertSubscriptionRemoteDataSource(world),
      mapper: mapper,
    );
    final preferences = NotificationPreferencesRepositoryImpl(
      remote: MockNotificationPreferencesRemoteDataSource(world),
      mapper: mapper,
    );
    final devices = DeviceTokenRepositoryImpl(
      MockDeviceTokenRemoteDataSource(world),
    );
    gateway = StubPushGateway(world.controls, logger);
    final activate = ActivateDeviceNotifications(
      gateway: gateway,
      devices: devices,
      tokenStore: tokenStore,
      pendingRemovals: pendingRemovals,
    );
    create = CreateAlertSubscription(
      subscriptions: subscriptions,
      activateDevice: activate,
    );
    list = ListAlertSubscriptions(subscriptions);
    remove = RemoveAlertSubscription(subscriptions);
    setActive = SetAlertSubscriptionActive(subscriptions);
    getPreferences = GetNotificationPreferences(preferences);
    savePreferences = SaveNotificationPreferences(preferences);
    this.activate = activate;
    unregister = UnregisterDeviceToken(
      devices: devices,
      tokenStore: tokenStore,
    );
  }

  final MockWorld world;
  final RecordingLogger logger = RecordingLogger();
  final KeyValueStore keyValues = InMemoryKeyValueStore();
  late final RegisteredPushTokenStoreImpl tokenStore =
      RegisteredPushTokenStoreImpl(keyValues);
  final MemoryPendingRemovalStore pendingRemovals = MemoryPendingRemovalStore();
  late final StubPushGateway gateway;
  late final ActivateDeviceNotifications activate;
  late final CreateAlertSubscription create;
  late final ListAlertSubscriptions list;
  late final RemoveAlertSubscription remove;
  late final SetAlertSubscriptionActive setActive;
  late final GetNotificationPreferences getPreferences;
  late final SaveNotificationPreferences savePreferences;
  late final UnregisterDeviceToken unregister;

  CreateAlertSubscriptionParams params({
    int lot = 1,
    Set<int> days = const {1, 3},
    int fromHour = 17,
    int toHour = 18,
  }) => CreateAlertSubscriptionParams(
    lotId: LotId(lot),
    days: days,
    from: time(fromHour, 0),
    to: time(toHour, 0),
  );
}

Suite newSuite({MockControls? controls}) => Suite(
  MockWorld(
    seed: testSeed,
    clock: FakeClock(),
    controls: controls,
    random: Random(1),
    latency: false,
  ),
);

void main() {
  group('mocks de notifications', () {
    test(
      'el mundo parte con tres franjas (una inactiva) y preferencias es-419',
      () async {
        final suite = newSuite();

        final subscriptions = (await suite.list(const NoParams())).valueOrNull!;
        final preferences = (await suite.getPreferences(
          const NoParams(),
        )).valueOrNull!;

        expect(subscriptions.map((s) => s.lotId), [
          const LotId(1),
          const LotId(2),
          const LotId(1),
        ]);
        expect(subscriptions.map((s) => s.active), [true, true, false]);
        expect(preferences.language, AlertLanguage.es);
        expect(preferences.pushEnabled, isTrue);
        expect(preferences.lowArrivalAlerts, isFalse);
        expect(preferences.staleDataAlerts, isTrue);
        expect(preferences.eventAlerts, isFalse);
        expect(suite.logger.messages, isEmpty);
      },
    );

    test(
      'crear agrega la suscripción; una idéntica a una activa da 409',
      () async {
        final suite = newSuite();

        final created = await suite.create(suite.params());
        final duplicate = await suite.create(suite.params());

        expect(created.valueOrNull?.subscription.lotId, const LotId(1));
        expect((await suite.list(const NoParams())).valueOrNull, hasLength(4));
        expect(duplicate.failureOrNull, isA<ValidationFailure>());
        expect(
          (duplicate.failureOrNull! as ValidationFailure).errors,
          contains('slot'),
        );
      },
    );

    test('un estacionamiento que no existe da 404', () async {
      final suite = newSuite();

      final result = await suite.create(suite.params(lot: 99));

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test(
      'dar de baja una conserva las demás; repetir la baja no falla',
      () async {
        final suite = newSuite();
        final seeded = (await suite.list(const NoParams())).valueOrNull!;
        final added = (await suite.create(
          suite.params(),
        )).valueOrNull!.subscription;

        expect((await suite.remove(seeded.first.id)).isSuccess, isTrue);
        expect((await suite.list(const NoParams())).valueOrNull, [
          seeded[1],
          seeded[2],
          added,
        ]);
        // Ya no existe: el servidor responde 404 y la app lo trata como éxito.
        expect((await suite.remove(seeded.first.id)).isSuccess, isTrue);
      },
    );

    test(
      'desactivar y reactivar conserva la franja; una que no existe da 404',
      () async {
        final suite = newSuite();
        final seeded = (await suite.list(const NoParams())).valueOrNull!;

        final off = await suite.setActive(
          SetAlertSubscriptionActiveParams(id: seeded.first.id, active: false),
        );
        expect(off.valueOrNull?.active, isFalse);
        expect((await suite.list(const NoParams())).valueOrNull, hasLength(3));

        final on = await suite.setActive(
          SetAlertSubscriptionActiveParams(id: seeded.first.id, active: true),
        );
        expect(on.valueOrNull?.active, isTrue);

        final gone = await suite.setActive(
          const SetAlertSubscriptionActiveParams(
            id: AlertSubscriptionId(99),
            active: true,
          ),
        );
        expect(gone.failureOrNull, isA<NotFoundFailure>());
      },
    );

    test('reactivar una franja idéntica a otra activa da 409', () async {
      final suite = newSuite();
      final seeded = (await suite.list(const NoParams())).valueOrNull!;
      // La tercera (inactiva) se vuelve idéntica a una activa: se crea la misma
      // franja y luego se reactiva la inactiva.
      final inactive = seeded.last;
      await suite.create(
        CreateAlertSubscriptionParams(
          lotId: inactive.lotId,
          days: {for (final day in inactive.days) day.isoNumber},
          from: inactive.slot.from,
          to: inactive.slot.to,
        ),
      );

      final result = await suite.setActive(
        SetAlertSubscriptionActiveParams(id: inactive.id, active: true),
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test(
      'guardar preferencias reemplaza todo y el idioma viaja como en-US',
      () async {
        final suite = newSuite();

        final saved = await suite.savePreferences(
          samplePreferences.copyWith(
            pushEnabled: false,
            language: AlertLanguage.en,
          ),
        );

        expect(saved.valueOrNull?.pushEnabled, isFalse);
        expect(suite.world.notifications.locale, 'en-US');
        expect(
          (await suite.getPreferences(const NoParams())).valueOrNull?.language,
          AlertLanguage.en,
        );
        expect(suite.logger.messages, isEmpty);
      },
    );

    test('un error de red forzado falla igual que el real', () async {
      final controls = MockControls()..forceNetworkError = true;
      final suite = newSuite(controls: controls);

      expect(
        (await suite.list(const NoParams())).failureOrNull,
        isA<NetworkFailure>(),
      );
    });
  });

  group('permiso y token (stub de PushGateway)', () {
    test(
      'suscribirse pide el permiso y registra el token una sola vez',
      () async {
        final suite = newSuite();
        // Al abrir la app el permiso no se ha pedido.
        expect(
          await suite.gateway.permissionStatus(),
          PushPermissionStatus.denied,
        );

        final first = await suite.create(suite.params());
        final second = await suite.create(
          suite.params(days: const {2}, fromHour: 6, toHour: 7),
        );

        expect(first.valueOrNull?.device, DeviceActivation.registered);
        expect(second.valueOrNull?.device, DeviceActivation.registered);
        expect(suite.world.notifications.deviceTokens, {
          StubPushGateway.mockToken,
        });
        expect(
          await suite.tokenStore.read(),
          pushToken(StubPushGateway.mockToken),
        );
      },
    );

    test(
      'permiso negado: la suscripción queda; la segunda negativa lo bloquea',
      () async {
        final controls = MockControls()..denyPushPermission = true;
        final suite = newSuite(controls: controls);

        final first = await suite.create(suite.params());
        final second = await suite.create(
          suite.params(days: const {2}, fromHour: 6, toHour: 7),
        );
        final third = await suite.create(
          suite.params(days: const {3}, fromHour: 6, toHour: 7),
        );

        expect(first.valueOrNull?.device, DeviceActivation.permissionDenied);
        expect(second.valueOrNull?.device, DeviceActivation.permissionBlocked);
        expect(third.valueOrNull?.device, DeviceActivation.permissionBlocked);
        expect((await suite.list(const NoParams())).valueOrNull, hasLength(6));
        expect(suite.world.notifications.deviceTokens, isEmpty);
      },
    );

    test(
      'cerrar sesión: el token se da de baja en el servidor y local',
      () async {
        final suite = newSuite();
        await suite.activate(const NoParams());
        expect(suite.world.notifications.deviceTokens, hasLength(1));

        final result = await suite.unregister(
          const UnregisterDeviceTokenParams(),
        );

        expect(result.isSuccess, isTrue);
        expect(suite.world.notifications.deviceTokens, isEmpty);
        expect(await suite.tokenStore.read(), isNull);
      },
    );

    test('sin red conserva el token para reintentar la baja', () async {
      final suite = newSuite();
      await suite.activate(const NoParams());
      suite.world.controls.forceNetworkError = true;

      final failed = await suite.unregister(
        const UnregisterDeviceTokenParams(),
      );

      expect(failed.failureOrNull, isA<NetworkFailure>());
      expect(await suite.tokenStore.read(), isNotNull);

      suite.world.controls.forceNetworkError = false;
      expect(
        (await suite.unregister(const UnregisterDeviceTokenParams())).isSuccess,
        isTrue,
      );
      expect(await suite.tokenStore.read(), isNull);
    });
  });

  group('coherencia entre contextos (solo por identificadores)', () {
    test(
      'las suscripciones apuntan a lotes de parking_configuration',
      () async {
        final suite = newSuite();
        await suite.create(suite.params(lot: 2));
        await suite.create(suite.params(lot: 3, days: const {4}));
        final lots = await MockParkingLotRemoteDataSource(suite.world).list();

        final subscriptions = (await suite.list(const NoParams())).valueOrNull!;

        final lotIds = lots.map((lot) => lot.id).toSet();
        expect(
          subscriptions.every((s) => lotIds.contains(s.lotId.value)),
          isTrue,
        );
      },
    );

    test(
      'tocar un push abre un lote que existe en parking_configuration',
      () async {
        final suite = newSuite();
        final lots = await MockParkingLotRemoteDataSource(suite.world).list();
        final received = <PushMessage>[];
        final subscription = suite.gateway.openedMessages.listen(received.add);

        suite.gateway
          ..simulateTap({'type': 'SATURATION', 'lotId': '2'})
          // Ignorados: no navegan a ninguna parte.
          ..simulateTap({'type': 'PROMO', 'lotId': '2'})
          ..simulateTap({'type': 'LOW_ARRIVAL', 'lotId': 'x'});
        await Future<void>.delayed(Duration.zero);
        await subscription.cancel();

        expect(received, hasLength(1));
        expect(received.single.type, PushMessageType.saturation);
        expect(
          lots.map((lot) => lot.id),
          contains(received.single.lotId.value),
        );
      },
    );
  });
}

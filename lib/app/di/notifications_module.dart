import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:quadrapp_mobile/app/config/app_config.dart';
import 'package:quadrapp_mobile/app/di/registrar.dart';
import 'package:quadrapp_mobile/app/mocks/mock_controls.dart';
import 'package:quadrapp_mobile/app/mocks/mock_world.dart';
import 'package:quadrapp_mobile/app/mocks/notifications/mock_notification_datasources.dart';
import 'package:quadrapp_mobile/app/mocks/notifications/stub_push_gateway.dart';
import 'package:quadrapp_mobile/contexts/notifications/application/usecases/activate_device_notifications.dart';
import 'package:quadrapp_mobile/contexts/notifications/application/usecases/create_alert_subscription.dart';
import 'package:quadrapp_mobile/contexts/notifications/application/usecases/device_token_usecases.dart';
import 'package:quadrapp_mobile/contexts/notifications/application/usecases/list_alert_subscriptions.dart';
import 'package:quadrapp_mobile/contexts/notifications/application/usecases/notification_preferences_usecases.dart';
import 'package:quadrapp_mobile/contexts/notifications/application/usecases/pending_token_removal_usecases.dart';
import 'package:quadrapp_mobile/contexts/notifications/application/usecases/remove_alert_subscription.dart';
import 'package:quadrapp_mobile/contexts/notifications/application/usecases/set_alert_subscription_active.dart';
import 'package:quadrapp_mobile/contexts/notifications/application/usecases/watch_push_messages.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/repositories/alert_subscription_repository.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/repositories/device_token_repository.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/repositories/notification_preferences_repository.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/repositories/pending_push_token_removal_store.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/repositories/push_gateway.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/repositories/registered_push_token_store.dart';
import 'package:quadrapp_mobile/contexts/notifications/infrastructure/datasources/notification_http_datasources.dart';
import 'package:quadrapp_mobile/contexts/notifications/infrastructure/datasources/notification_remote_datasources.dart';
import 'package:quadrapp_mobile/contexts/notifications/infrastructure/mappers/notifications_mapper.dart';
import 'package:quadrapp_mobile/contexts/notifications/infrastructure/push/unavailable_push_gateway.dart';
import 'package:quadrapp_mobile/contexts/notifications/infrastructure/repositories/notification_repositories.dart';
import 'package:quadrapp_mobile/contexts/notifications/infrastructure/repositories/pending_push_token_removal_store_impl.dart';
import 'package:quadrapp_mobile/contexts/notifications/infrastructure/repositories/registered_push_token_store_impl.dart';
import 'package:quadrapp_mobile/core/logging/logger.dart';
import 'package:quadrapp_mobile/core/storage/key_value_store.dart';

/// Contexto `notifications`: alertas, preferencias y token push (US33–US35,
/// US02 esc. 3).
///
/// - El token registrado (`user.pushToken`) se limpia al cerrar sesión por su
///   prefijo.
/// - La baja pendiente (`device.pendingPushTokenRemoval`) **no**: es una de las
///   dos excepciones declaradas (la otra es el idioma) y solo contiene el
///   token del dispositivo.
/// - `PushGateway`: con mocks, el stub; en ejecución real,
///   `UnavailablePushGateway` hasta que la fase 6 integre `firebase_messaging`
///   (solo cambia aquí).
void registerNotificationsModule(GetIt locator, AppConfig config) {
  locator
    // --- infraestructura ---
    ..addLazy<AlertSubscriptionRemoteDataSource>(
      () => config.useMocks
          ? MockAlertSubscriptionRemoteDataSource(locator<MockWorld>())
          : AlertSubscriptionHttpDataSource(locator<Dio>()),
    )
    ..addLazy<NotificationPreferencesRemoteDataSource>(
      () => config.useMocks
          ? MockNotificationPreferencesRemoteDataSource(locator<MockWorld>())
          : NotificationPreferencesHttpDataSource(locator<Dio>()),
    )
    ..addLazy<DeviceTokenRemoteDataSource>(
      () => config.useMocks
          ? MockDeviceTokenRemoteDataSource(locator<MockWorld>())
          : DeviceTokenHttpDataSource(locator<Dio>()),
    )
    ..addLazy<NotificationsMapper>(
      () => NotificationsMapper(locator<Logger>()),
    )
    ..addLazy<AlertSubscriptionRepository>(
      () => AlertSubscriptionRepositoryImpl(
        remote: locator(),
        mapper: locator(),
      ),
    )
    ..addLazy<NotificationPreferencesRepository>(
      () => NotificationPreferencesRepositoryImpl(
        remote: locator(),
        mapper: locator(),
      ),
    )
    ..addLazy<DeviceTokenRepository>(() => DeviceTokenRepositoryImpl(locator()))
    ..addLazy<RegisteredPushTokenStore>(
      () => RegisteredPushTokenStoreImpl(locator<KeyValueStore>()),
    )
    ..addLazy<PendingPushTokenRemovalStore>(
      () => PendingPushTokenRemovalStoreImpl(locator<KeyValueStore>()),
    )
    ..addLazy<PushGateway>(
      () => config.useMocks
          ? StubPushGateway(locator<MockControls>(), locator<Logger>())
          : const UnavailablePushGateway(),
    )
    // --- casos de uso ---
    ..addLazy<ListAlertSubscriptions>(() => ListAlertSubscriptions(locator()))
    ..addLazy<SetAlertSubscriptionActive>(
      () => SetAlertSubscriptionActive(locator()),
    )
    ..addLazy<RemoveAlertSubscription>(
      () => RemoveAlertSubscription(locator()),
    )
    ..addLazy<GetNotificationPreferences>(
      () => GetNotificationPreferences(locator()),
    )
    ..addLazy<SaveNotificationPreferences>(
      () => SaveNotificationPreferences(locator()),
    )
    ..addLazy<WatchPushMessages>(() => WatchPushMessages(locator()))
    ..addLazy<GetRegisteredPushToken>(() => GetRegisteredPushToken(locator()))
    ..addLazy<UnregisterDeviceToken>(
      () => UnregisterDeviceToken(devices: locator(), tokenStore: locator()),
    )
    ..addLazy<ActivateDeviceNotifications>(
      () => ActivateDeviceNotifications(
        gateway: locator(),
        devices: locator(),
        tokenStore: locator(),
        pendingRemovals: locator(),
      ),
    )
    ..addLazy<CreateAlertSubscription>(
      () => CreateAlertSubscription(
        subscriptions: locator(),
        activateDevice: locator(),
      ),
    )
    ..addLazy<RemoveDeviceTokenOnSignOut>(
      () => RemoveDeviceTokenOnSignOut(
        unregister: locator(),
        pendingRemovals: locator(),
      ),
    )
    ..addLazy<RetryPendingTokenRemoval>(
      () => RetryPendingTokenRemoval(
        devices: locator(),
        pendingRemovals: locator(),
      ),
    );
}

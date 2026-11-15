import 'package:quadrapp_mobile/contexts/notifications/infrastructure/dto/notification_dtos.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

/// Origen remoto de las suscripciones (HTTP o mock): mismos errores, mismos
/// formatos, mismas garantías.
abstract interface class AlertSubscriptionRemoteDataSource {
  /// `GET /notification-subscriptions`.
  Future<List<AlertSubscriptionDto>> list();

  /// `POST /notification-subscriptions`.
  Future<AlertSubscriptionDto> create(AlertSubscriptionRequestDto request);

  /// `PATCH /notification-subscriptions/{id}` con `{ active }`.
  Future<AlertSubscriptionDto> setActive(
    AlertSubscriptionId id,
    AlertSubscriptionActiveRequestDto request,
  );

  /// `DELETE /notification-subscriptions/{id}`: la baja definitiva.
  Future<void> remove(AlertSubscriptionId id);
}

/// Origen remoto de las preferencias (HTTP o mock).
abstract interface class NotificationPreferencesRemoteDataSource {
  /// `GET /notification-preferences`.
  Future<NotificationPreferencesDto> get();

  /// `PUT /notification-preferences`.
  Future<NotificationPreferencesDto> save(NotificationPreferencesDto dto);
}

/// Origen remoto de los tokens de dispositivo (HTTP o mock).
abstract interface class DeviceTokenRemoteDataSource {
  /// `POST /device-tokens`.
  Future<void> register(DeviceTokenRequestDto request);

  /// `POST /device-tokens/unregister` con `{ token }` en el cuerpo. No
  /// requiere sesión (docs/07).
  Future<void> unregister(DeviceTokenUnregisterRequestDto request);
}

import 'package:quadrapp_mobile/contexts/notifications/domain/entities/alert_subscription.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/entities/notification_preferences.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/repositories/alert_subscription_repository.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/repositories/device_token_repository.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/repositories/notification_preferences_repository.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/value_objects/push_token.dart';
import 'package:quadrapp_mobile/contexts/notifications/infrastructure/datasources/notification_remote_datasources.dart';
import 'package:quadrapp_mobile/contexts/notifications/infrastructure/dto/notification_dtos.dart';
import 'package:quadrapp_mobile/contexts/notifications/infrastructure/mappers/notifications_mapper.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/network/failure_mapper.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// Un 404 al dar de baja algo que ya no existe es un éxito (docs/07).
Result<void> _goneIsSuccess(Result<void> result) =>
    result.failureOrNull is NotFoundFailure
    ? const Success<void>(null)
    : result;

/// Las suscripciones del servidor. Sin caché: las suscripciones y las
/// preferencias solo se usan con conexión (TS13 solo cubre layout y ocupación).
class AlertSubscriptionRepositoryImpl implements AlertSubscriptionRepository {
  const AlertSubscriptionRepositoryImpl({
    required this._remote,
    required this._mapper,
  });

  final AlertSubscriptionRemoteDataSource _remote;
  final NotificationsMapper _mapper;

  @override
  Future<Result<List<AlertSubscription>>> list() => guardResult(
    () async => _mapper.toSubscriptions(await _remote.list()),
  );

  @override
  Future<Result<AlertSubscription>> create(AlertSubscriptionDraft draft) =>
      guardResult(
        () async => _mapper.toSubscription(
          await _remote.create(_mapper.toRequestDto(draft)),
        ),
      );

  @override
  Future<Result<AlertSubscription>> setActive(
    AlertSubscriptionId id, {
    required bool active,
  }) => guardResult(
    () async => _mapper.toSubscription(
      await _remote.setActive(
        id,
        AlertSubscriptionActiveRequestDto(active: active),
      ),
    ),
  );

  @override
  Future<Result<void>> remove(AlertSubscriptionId id) async =>
      _goneIsSuccess(await guardResult(() => _remote.remove(id)));
}

/// Las preferencias de notificación del servidor.
class NotificationPreferencesRepositoryImpl
    implements NotificationPreferencesRepository {
  const NotificationPreferencesRepositoryImpl({
    required this._remote,
    required this._mapper,
  });

  final NotificationPreferencesRemoteDataSource _remote;
  final NotificationsMapper _mapper;

  @override
  Future<Result<NotificationPreferences>> get() =>
      guardResult(() async => _mapper.toPreferences(await _remote.get()));

  @override
  Future<Result<NotificationPreferences>> save(
    NotificationPreferences preferences,
  ) => guardResult(
    () async => _mapper.toPreferences(
      await _remote.save(_mapper.toPreferencesDto(preferences)),
    ),
  );
}

/// Los tokens de dispositivo del servidor. Esta app es solo Android.
class DeviceTokenRepositoryImpl implements DeviceTokenRepository {
  const DeviceTokenRepositoryImpl(this._remote);

  final DeviceTokenRemoteDataSource _remote;

  /// Valor de `platform` de esta app (docs/06 también admite `IOS` y `WEB`).
  static const String platform = 'ANDROID';

  @override
  Future<Result<void>> register(PushToken token) => guardResult(
    () => _remote.register(
      DeviceTokenRequestDto(token: token.value, platform: platform),
    ),
  );

  @override
  Future<Result<void>> unregister(PushToken token) async => _goneIsSuccess(
    await guardResult(
      () => _remote.unregister(
        DeviceTokenUnregisterRequestDto(token: token.value),
      ),
    ),
  );
}

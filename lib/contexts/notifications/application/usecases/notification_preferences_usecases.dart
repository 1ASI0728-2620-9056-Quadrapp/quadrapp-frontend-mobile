// US24, TS12
import 'package:quadrapp_mobile/contexts/notifications/domain/entities/notification_preferences.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/repositories/notification_preferences_repository.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

/// Las preferencias de notificación guardadas (US24 esc. 1).
class GetNotificationPreferences
    implements UseCase<NotificationPreferences, NoParams> {
  const GetNotificationPreferences(this._preferences);

  final NotificationPreferencesRepository _preferences;

  @override
  Future<Result<NotificationPreferences>> call(NoParams params) =>
      _preferences.get();
}

/// Guarda las preferencias (US24 esc. 1 a 3). Devuelve las guardadas.
///
/// Que estén desactivadas solo se refleja aquí: omitir el envío lo hace el
/// servidor (US23 esc. 3).
class SaveNotificationPreferences
    implements UseCase<NotificationPreferences, NotificationPreferences> {
  const SaveNotificationPreferences(this._preferences);

  final NotificationPreferencesRepository _preferences;

  @override
  Future<Result<NotificationPreferences>> call(
    NotificationPreferences preferences,
  ) => _preferences.save(preferences);
}

import 'package:quadrapp_mobile/contexts/notifications/domain/entities/notification_preferences.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// Las preferencias de notificación en el servidor (US24).
abstract interface class NotificationPreferencesRepository {
  Future<Result<NotificationPreferences>> get();

  /// Reemplaza todas las preferencias y devuelve las guardadas.
  Future<Result<NotificationPreferences>> save(
    NotificationPreferences preferences,
  );
}

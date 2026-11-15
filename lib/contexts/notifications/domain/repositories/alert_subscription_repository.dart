import 'package:quadrapp_mobile/contexts/notifications/domain/entities/alert_subscription.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// Las suscripciones del conductor en el servidor (US33).
abstract interface class AlertSubscriptionRepository {
  /// Las suscripciones activas.
  Future<Result<List<AlertSubscription>>> list();

  Future<Result<AlertSubscription>> create(AlertSubscriptionDraft draft);

  /// Activa o desactiva una suscripción sin perderla (US33 esc. 3).
  Future<Result<AlertSubscription>> setActive(
    AlertSubscriptionId id, {
    required bool active,
  });

  /// Da de baja una suscripción y conserva las demás (US33 esc. 3). Que ya no
  /// exista cuenta como éxito.
  Future<Result<void>> remove(AlertSubscriptionId id);
}

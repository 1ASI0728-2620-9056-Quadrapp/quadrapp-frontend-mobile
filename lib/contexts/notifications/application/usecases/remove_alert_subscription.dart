// US33 (esc. 3)
import 'package:quadrapp_mobile/contexts/notifications/domain/repositories/alert_subscription_repository.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

/// Da de baja una suscripción. Las demás no se tocan.
class RemoveAlertSubscription implements UseCase<void, AlertSubscriptionId> {
  const RemoveAlertSubscription(this._subscriptions);

  final AlertSubscriptionRepository _subscriptions;

  @override
  Future<Result<void>> call(AlertSubscriptionId id) =>
      _subscriptions.remove(id);
}

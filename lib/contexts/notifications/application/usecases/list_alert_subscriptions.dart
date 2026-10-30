// US23, US33
import 'package:quadrapp_mobile/contexts/notifications/domain/entities/alert_subscription.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/repositories/alert_subscription_repository.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

/// Las suscripciones activas del conductor. Una lista vacía es el estado
/// "aún no sigues ninguna franja" (docs/05), no un error.
class ListAlertSubscriptions
    implements UseCase<List<AlertSubscription>, NoParams> {
  const ListAlertSubscriptions(this._subscriptions);

  final AlertSubscriptionRepository _subscriptions;

  @override
  Future<Result<List<AlertSubscription>>> call(NoParams params) =>
      _subscriptions.list();
}

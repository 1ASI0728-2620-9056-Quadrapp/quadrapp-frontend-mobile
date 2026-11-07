// US33 (esc. 3)
import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/entities/alert_subscription.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/repositories/alert_subscription_repository.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

/// Parámetros de [SetAlertSubscriptionActive].
class SetAlertSubscriptionActiveParams extends Equatable {
  const SetAlertSubscriptionActiveParams({
    required this.id,
    required this.active,
  });

  final AlertSubscriptionId id;
  final bool active;

  @override
  List<Object?> get props => [id.value, active];
}

/// Activa o desactiva una franja. Desactivar la conserva y deja de enviar
/// alertas para ella; las demás no cambian (US33 esc. 3). Reactivar una franja
/// idéntica a otra activa es un `ValidationFailure` (409).
class SetAlertSubscriptionActive
    implements UseCase<AlertSubscription, SetAlertSubscriptionActiveParams> {
  const SetAlertSubscriptionActive(this._subscriptions);

  final AlertSubscriptionRepository _subscriptions;

  @override
  Future<Result<AlertSubscription>> call(
    SetAlertSubscriptionActiveParams params,
  ) => _subscriptions.setActive(params.id, active: params.active);
}

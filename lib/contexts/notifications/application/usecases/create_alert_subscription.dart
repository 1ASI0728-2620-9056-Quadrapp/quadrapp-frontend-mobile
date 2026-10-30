// US33, TS12
import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/notifications/application/usecases/activate_device_notifications.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/entities/alert_subscription.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/entities/device_activation.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/repositories/alert_subscription_repository.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/value_objects/clock_time.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

class CreateAlertSubscriptionParams extends Equatable {
  const CreateAlertSubscriptionParams({
    required this.lotId,
    required this.days,
    required this.from,
    required this.to,
  });

  final LotId lotId;

  /// 1 = lunes ... 7 = domingo.
  final Set<int> days;
  final ClockTime from;
  final ClockTime to;

  @override
  List<Object?> get props => [lotId.value, days, from, to];
}

/// La suscripción creada y qué pasó con el dispositivo.
class CreatedAlertSubscription extends Equatable {
  const CreatedAlertSubscription({
    required this.subscription,
    required this.device,
  });

  final AlertSubscription subscription;

  /// Si este dispositivo quedó habilitado para recibir las alertas. Si no, la
  /// suscripción igual quedó registrada y la pantalla lo explica.
  final DeviceActivation device;

  @override
  List<Object?> get props => [subscription, device];
}

/// Suscribe al conductor a una franja de un estacionamiento (US33 esc. 1) y,
/// con la suscripción ya registrada, habilita este dispositivo (US33 esc. 2):
/// ahí se pide, con contexto, el permiso de notificaciones.
///
/// El permiso no se pide si la suscripción no se pudo crear. Que el dispositivo
/// no quede habilitado (permiso negado, sin red al registrar el token) no
/// deshace la suscripción: queda registrada en el servidor.
class CreateAlertSubscription
    implements
        UseCase<CreatedAlertSubscription, CreateAlertSubscriptionParams> {
  const CreateAlertSubscription({
    required this._subscriptions,
    required this._activateDevice,
  });

  final AlertSubscriptionRepository _subscriptions;
  final ActivateDeviceNotifications _activateDevice;

  @override
  Future<Result<CreatedAlertSubscription>> call(
    CreateAlertSubscriptionParams params,
  ) async {
    final AlertSubscriptionDraft draft;
    switch (AlertSubscriptionDraft.create(
      lotId: params.lotId,
      days: params.days,
      from: params.from,
      to: params.to,
    )) {
      case Err(:final failure):
        return Err(failure);
      case Success(value: final valid):
        draft = valid;
    }

    final AlertSubscription subscription;
    switch (await _subscriptions.create(draft)) {
      case Err(:final failure):
        return Err(failure);
      case Success(value: final created):
        subscription = created;
    }

    final activation = await _activateDevice(const NoParams());
    return Success(
      CreatedAlertSubscription(
        subscription: subscription,
        device: activation.valueOrNull ?? DeviceActivation.registrationFailed,
      ),
    );
  }
}

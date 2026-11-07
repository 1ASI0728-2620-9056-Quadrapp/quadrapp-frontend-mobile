// US23, US24, US33
import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/notifications/notifications.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';

/// Qué alerta enciende o apaga cada interruptor de «Avísame cuando» (US24).
enum AlertPreference {
  /// Se prevé que el estacionamiento se llene en una franja que sigue (US23
  /// esc. 1).
  saturation,

  /// La disponibilidad para su hora estimada de llegada es baja (US23 esc. 2).
  lowArrival,

  /// Los datos llevan más de 10 minutos sin lectura.
  staleData,

  /// Cambios por eventos del calendario del campus.
  events,
}

/// Avisos breves que el cubit le pide a la pantalla (un aviso emergente). No
/// son estado: se muestran una vez.
enum AlertsNotice {
  permissionDenied,
  permissionBlocked,
  activationFailed,
  saveFailed,
  slotFailed,
  slotDuplicate,
  deleteFailed,
  deleted,
  created,
  createdDenied,
  createdBlocked,
  createdNoDevice,
}

/// Lo que muestra Alertas: las preferencias y las franjas del conductor.
/// Cualquiera de las dos puede faltar sin tumbar la otra. Es estado de
/// presentación: no es una entidad del dominio.
class AlertsOverview extends Equatable {
  const AlertsOverview({
    this.preferences,
    this.subscriptions,
    this.preferencesFailure,
    this.subscriptionsFailure,
  });

  final NotificationPreferences? preferences;

  /// Las franjas, activas e inactivas (una desactivada se conserva).
  final List<AlertSubscription>? subscriptions;
  final Failure? preferencesFailure;
  final Failure? subscriptionsFailure;

  AlertsOverview copyWith({
    NotificationPreferences? preferences,
    List<AlertSubscription>? subscriptions,
  }) => AlertsOverview(
    preferences: preferences ?? this.preferences,
    subscriptions: subscriptions ?? this.subscriptions,
    preferencesFailure: preferencesFailure,
    subscriptionsFailure: subscriptionsFailure,
  );

  @override
  List<Object?> get props => [
    preferences,
    subscriptions,
    preferencesFailure,
    subscriptionsFailure,
  ];
}

/// El valor de [kind] en [preferences].
bool preferenceValue(
  NotificationPreferences preferences,
  AlertPreference kind,
) => switch (kind) {
  AlertPreference.saturation => preferences.saturationAlerts,
  AlertPreference.lowArrival => preferences.lowArrivalAlerts,
  AlertPreference.staleData => preferences.staleDataAlerts,
  AlertPreference.events => preferences.eventAlerts,
};

/// [preferences] con [kind] en [value].
NotificationPreferences withPreference(
  NotificationPreferences preferences,
  AlertPreference kind, {
  required bool value,
}) => switch (kind) {
  AlertPreference.saturation => preferences.copyWith(saturationAlerts: value),
  AlertPreference.lowArrival => preferences.copyWith(lowArrivalAlerts: value),
  AlertPreference.staleData => preferences.copyWith(staleDataAlerts: value),
  AlertPreference.events => preferences.copyWith(eventAlerts: value),
};

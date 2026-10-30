// US24
import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/value_objects/alert_language.dart';

/// Qué alertas quiere recibir el conductor y en qué idioma (US24). Que estén
/// desactivadas se refleja aquí; el envío (o su omisión) lo decide el servidor
/// (US23 esc. 3).
class NotificationPreferences extends Equatable {
  const NotificationPreferences({
    required this.pushEnabled,
    required this.saturationAlerts,
    required this.lowArrivalAlerts,
    required this.staleDataAlerts,
    required this.eventAlerts,
    required this.language,
  });

  /// Interruptor general de las notificaciones push.
  final bool pushEnabled;

  /// Alertas por saturación prevista en una franja suscrita (US23 esc. 1).
  final bool saturationAlerts;

  /// Aviso de baja probabilidad al consultar la asesoría (US23 esc. 2).
  final bool lowArrivalAlerts;

  /// Aviso de que los datos del estacionamiento llevan demasiado tiempo sin
  /// actualizarse (más de 10 minutos sin lectura).
  final bool staleDataAlerts;

  /// Aviso de cambios por eventos del calendario del campus.
  final bool eventAlerts;

  /// Idioma de las alertas: el de la app.
  final AlertLanguage language;

  NotificationPreferences copyWith({
    bool? pushEnabled,
    bool? saturationAlerts,
    bool? lowArrivalAlerts,
    bool? staleDataAlerts,
    bool? eventAlerts,
    AlertLanguage? language,
  }) => NotificationPreferences(
    pushEnabled: pushEnabled ?? this.pushEnabled,
    saturationAlerts: saturationAlerts ?? this.saturationAlerts,
    lowArrivalAlerts: lowArrivalAlerts ?? this.lowArrivalAlerts,
    staleDataAlerts: staleDataAlerts ?? this.staleDataAlerts,
    eventAlerts: eventAlerts ?? this.eventAlerts,
    language: language ?? this.language,
  );

  @override
  List<Object?> get props => [
    pushEnabled,
    saturationAlerts,
    lowArrivalAlerts,
    staleDataAlerts,
    eventAlerts,
    language,
  ];
}

import 'package:quadrapp_mobile/composition/alerts/alerts_state.dart';
import 'package:quadrapp_mobile/contexts/notifications/notifications.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

ClockTime time(int hour, int minute) =>
    ClockTime.create(hour, minute).valueOrNull!;

const preferences = NotificationPreferences(
  pushEnabled: true,
  saturationAlerts: true,
  lowArrivalAlerts: false,
  staleDataAlerts: true,
  eventAlerts: false,
  language: AlertLanguage.es,
);

AlertSubscription subscription({
  int id = 1,
  int lot = 1,
  List<AlertDay> days = const [
    AlertDay.monday,
    AlertDay.tuesday,
    AlertDay.wednesday,
    AlertDay.thursday,
    AlertDay.friday,
  ],
  int fromHour = 7,
  int fromMinute = 30,
  int toHour = 9,
  bool active = true,
}) => AlertSubscription(
  id: AlertSubscriptionId(id),
  lotId: LotId(lot),
  days: days,
  slot: AlertTimeSlot.create(
    from: time(fromHour, fromMinute),
    to: time(toHour, 0),
  ).valueOrNull!,
  active: active,
);

/// Una franja activa de Monterrico, otra activa de San Isidro y una pausada.
List<AlertSubscription> sampleSubscriptions() => [
  subscription(),
  subscription(
    id: 2,
    lot: 2,
    days: const [AlertDay.monday, AlertDay.wednesday, AlertDay.friday],
    fromHour: 13,
    fromMinute: 0,
    toHour: 14,
  ),
  subscription(
    id: 3,
    days: const [AlertDay.saturday],
    fromHour: 9,
    fromMinute: 0,
    toHour: 11,
    active: false,
  ),
];

AlertsOverview overview({
  NotificationPreferences? prefs = preferences,
  List<AlertSubscription>? subscriptions,
  bool withSubscriptions = true,
}) => AlertsOverview(
  preferences: prefs,
  subscriptions: withSubscriptions
      ? (subscriptions ?? sampleSubscriptions())
      : null,
);

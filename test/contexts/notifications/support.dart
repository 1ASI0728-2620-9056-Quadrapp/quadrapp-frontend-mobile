import 'package:quadrapp_mobile/contexts/notifications/domain/entities/alert_subscription.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/entities/notification_preferences.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/repositories/pending_push_token_removal_store.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/value_objects/alert_day.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/value_objects/alert_language.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/value_objects/alert_time_slot.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/value_objects/clock_time.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/value_objects/push_token.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

const lotId = LotId(1);

/// La baja pendiente del token push, en memoria.
class MemoryPendingRemovalStore implements PendingPushTokenRemovalStore {
  PushToken? pending;

  @override
  Future<PushToken?> read() async => pending;

  @override
  Future<void> save(PushToken token) async => pending = token;

  @override
  Future<void> clear() async => pending = null;
}

ClockTime time(int hour, int minute) =>
    ClockTime.create(hour, minute).valueOrNull ?? (throw StateError('hora'));

PushToken pushToken([String value = 'fcm:token-1']) =>
    PushToken.create(value).valueOrNull ?? (throw StateError('token'));

AlertSubscriptionDraft sampleDraft({
  LotId lot = lotId,
  Set<int> days = const {1, 2, 3, 4, 5},
}) =>
    AlertSubscriptionDraft.create(
      lotId: lot,
      days: days,
      from: time(7, 30),
      to: time(9, 0),
    ).valueOrNull ??
    (throw StateError('borrador'));

AlertSubscription sampleSubscription({
  int id = 1,
  LotId lot = lotId,
  List<AlertDay> days = const [AlertDay.monday, AlertDay.friday],
}) => AlertSubscription(
  id: AlertSubscriptionId(id),
  lotId: lot,
  days: days,
  slot:
      AlertTimeSlot.create(from: time(7, 30), to: time(9, 0)).valueOrNull ??
      (throw StateError('franja')),
);

const samplePreferences = NotificationPreferences(
  pushEnabled: true,
  saturationAlerts: true,
  lowArrivalAlerts: false,
  staleDataAlerts: true,
  eventAlerts: false,
  language: AlertLanguage.es,
);

/// `GET /notification-subscriptions` (un elemento) con el formato de docs/07.
Map<String, Object?> subscriptionJson({
  int id = 1,
  int lot = 1,
  List<int> days = const [1, 2, 3, 4, 5],
  String from = '07:30',
  String to = '09:00',
  bool active = true,
}) => {
  'id': id,
  'lotId': lot,
  'days': days,
  'from': from,
  'to': to,
  'active': active,
};

/// `GET /notification-preferences` con el formato de docs/07.
Map<String, Object?> preferencesJson({String locale = 'es-419'}) => {
  'pushEnabled': true,
  'saturationAlerts': true,
  'lowArrivalAlerts': false,
  'locale': locale,
};

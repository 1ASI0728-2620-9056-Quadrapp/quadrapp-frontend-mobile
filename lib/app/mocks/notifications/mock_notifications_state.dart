import 'package:quadrapp_mobile/app/mocks/mock_seed.dart';

/// Una suscripción en el mundo simulado (valores tal cual los envía el
/// backend: días 1 a 7, horas `"HH:mm"`).
class MockSubscription {
  MockSubscription({
    required this.id,
    required this.lotId,
    required this.days,
    required this.from,
    required this.to,
    this.active = true,
  });

  final int id;
  final int lotId;
  final List<int> days;
  final String from;
  final String to;
  bool active;

  Map<String, Object?> toJson() => {
    'id': id,
    'lotId': lotId,
    'days': days,
    'from': from,
    'to': to,
    'active': active,
  };
}

/// Estado de notificaciones del "servidor": suscripciones, preferencias y
/// tokens de dispositivo. Vive en `MockWorld`, así los estacionamientos a los
/// que apuntan las suscripciones son los mismos que lista
/// `parking_configuration`.
///
/// Las suscripciones y las preferencias de partida salen de la semilla
/// (`assets/mocks/seed.json`).
class MockNotificationsState {
  MockNotificationsState(MockSeed seed) {
    loadSeed(seed);
  }

  final List<MockSubscription> subscriptions = [];

  /// Los tokens de dispositivo registrados.
  final Set<String> deviceTokens = {};

  late bool pushEnabled;
  late bool saturationAlerts;
  late bool lowArrivalAlerts;
  late bool staleDataAlerts;
  late bool eventAlerts;

  /// El idioma de las alertas del servidor (docs/06: `es-419` por defecto).
  late String locale;

  int _nextId = 1;

  int nextSubscriptionId() => _nextId++;

  /// Vuelve a las suscripciones y preferencias de la semilla. Los tokens de
  /// dispositivo registrados se conservan: son del teléfono, no de los datos
  /// de prueba.
  void loadSeed(MockSeed seed) {
    subscriptions.clear();
    _nextId = 1;
    for (final sub in seed.subscriptions) {
      subscriptions.add(
        MockSubscription(
          id: sub.id,
          lotId: sub.lotId,
          days: sub.days,
          from: sub.from,
          to: sub.to,
          active: sub.active,
        ),
      );
      if (sub.id >= _nextId) _nextId = sub.id + 1;
    }
    final prefs = seed.preferences;
    pushEnabled = prefs['pushEnabled'] as bool;
    saturationAlerts = prefs['saturationAlerts'] as bool;
    lowArrivalAlerts = prefs['lowArrivalAlerts'] as bool;
    staleDataAlerts = prefs['staleDataAlerts'] as bool? ?? true;
    eventAlerts = prefs['eventAlerts'] as bool? ?? false;
    locale = prefs['locale'] as String;
  }

  Iterable<MockSubscription> get active => subscriptions.where((s) => s.active);

  Map<String, Object?> preferencesJson() => {
    'pushEnabled': pushEnabled,
    'saturationAlerts': saturationAlerts,
    'lowArrivalAlerts': lowArrivalAlerts,
    'staleDataAlerts': staleDataAlerts,
    'eventAlerts': eventAlerts,
    'locale': locale,
  };
}

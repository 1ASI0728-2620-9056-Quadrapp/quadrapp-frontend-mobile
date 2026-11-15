import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:quadrapp_mobile/app/mocks/mock_devices.dart';
import 'package:quadrapp_mobile/app/mocks/mock_lots.dart';

/// Un usuario de prueba de la semilla (docs/07).
class MockSeedUser {
  const MockSeedUser({
    required this.id,
    required this.email,
    required this.role,
    this.fullName,
  });

  final int id;
  final String email;
  final String role;

  /// `users.full_name`: puede faltar.
  final String? fullName;
}

/// Una suscripción de alerta de la semilla (docs/07).
class MockSeedSubscription {
  const MockSeedSubscription({
    required this.id,
    required this.lotId,
    required this.days,
    required this.from,
    required this.to,
    required this.active,
  });

  final int id;
  final int lotId;
  final List<int> days;
  final String from;
  final String to;
  final bool active;
}

/// Los datos de prueba de `assets/mocks/seed.json`, ya leídos.
///
/// El archivo sigue la forma de docs/07 y docs/06 y no trae textos de
/// presentación: las marcas de tiempo son desplazamientos relativos
/// (`ageSeconds`) que [buildLots] resuelve contra la hora que se le pase, así
/// que nunca quedan viejas. Leer la semilla no cambia nada: [buildLots] arma
/// objetos nuevos cada vez (así `MockWorld.reset` vuelve al principio).
class MockSeed {
  MockSeed(this._json);

  /// Lee la semilla desde su texto JSON.
  factory MockSeed.parse(String source) =>
      MockSeed(jsonDecode(source) as Map<String, dynamic>);

  /// Lee la semilla empaquetada como asset.
  static Future<MockSeed> load(
    AssetBundle bundle, {
    String path = assetPath,
  }) async => MockSeed.parse(await bundle.loadString(path));

  static const String assetPath = 'assets/mocks/seed.json';

  final Map<String, dynamic> _json;

  Map<String, dynamic> get _institution =>
      _json['institution'] as Map<String, dynamic>;

  int get institutionId => _institution['id'] as int;
  String get institutionName => _institution['name'] as String;
  String get domain => _institution['domain'] as String;

  /// El código de un solo uso que acepta el servidor de prueba.
  String get otpCode =>
      (_json['auth'] as Map<String, dynamic>)['otpCode'] as String;

  List<MockSeedUser> get users => [
    for (final user in _json['users'] as List<dynamic>)
      MockSeedUser(
        id: (user as Map<String, dynamic>)['id'] as int,
        email: user['email'] as String,
        role: user['role'] as String,
        fullName: user['fullName'] as String?,
      ),
  ];

  List<MockSeedSubscription> get subscriptions => [
    for (final sub in _json['alertSubscriptions'] as List<dynamic>)
      MockSeedSubscription(
        id: (sub as Map<String, dynamic>)['id'] as int,
        lotId: sub['lotId'] as int,
        days: (sub['days'] as List<dynamic>).cast<int>(),
        from: sub['from'] as String,
        to: sub['to'] as String,
        active: sub['active'] as bool,
      ),
  ];

  Map<String, dynamic> get preferences =>
      _json['notificationPreferences'] as Map<String, dynamic>;

  /// Los estacionamientos que el simulador mueve (los demás quedan quietos,
  /// por ejemplo el de dato vencido).
  Set<int> get simulatedLotIds =>
      ((_json['simulator'] as Map<String, dynamic>)['lotIds'] as List<dynamic>)
          .cast<int>()
          .toSet();

  /// Arma los estacionamientos, con el dato consolidado [now] menos su
  /// `ageSeconds`.
  List<MockLot> buildLots(DateTime now) => [
    for (final raw in _json['parkingLots'] as List<dynamic>)
      _buildLot(raw as Map<String, dynamic>, now),
  ];

  /// Arma los dispositivos de todos los estacionamientos, con su última
  /// comunicación [now] menos su `lastSeenAgeSeconds`.
  List<MockDevice> buildDevices(DateTime now) => [
    for (final lot in _json['parkingLots'] as List<dynamic>)
      for (final raw
          in (lot as Map<String, dynamic>)['devices'] as List<dynamic>)
        _buildDevice(raw as Map<String, dynamic>, lot['id'] as int, now),
  ];

  MockDevice _buildDevice(Map<String, dynamic> raw, int lotId, DateTime now) {
    final age = raw['lastSeenAgeSeconds'] as int?;
    return MockDevice(
      id: raw['id'] as int,
      lotId: lotId,
      hardwareId: raw['hardwareId'] as String,
      type: raw['type'] as String,
      status: raw['status'] as String,
      expectedReportIntervalSec: raw['expectedReportIntervalSec'] as int,
      batteryPct: raw['batteryPct'] as int?,
      lastSeen: age == null ? null : now.subtract(Duration(seconds: age)),
      directional: raw['directional'] as bool?,
      spaceId: raw['spaceId'] as int?,
    );
  }

  MockLot _buildLot(Map<String, dynamic> raw, DateTime now) {
    final console = raw['console'] as Map<String, dynamic>?;
    final flow = console?['flow'] as Map<String, dynamic>?;
    final occupancy = raw['occupancy'] as Map<String, dynamic>?;
    final age = Duration(seconds: (occupancy?['ageSeconds'] as int?) ?? 0);
    return MockLot(
      id: raw['id'] as int,
      name: raw['name'] as String,
      address: raw['address'] as String?,
      latitude: (raw['latitude'] as num?)?.toDouble(),
      longitude: (raw['longitude'] as num?)?.toDouble(),
      layoutVersion: raw['layoutVersion'] as int,
      staleAfterSeconds: raw['staleAfterSeconds'] as int,
      saturationThresholdPct: raw['saturationThresholdPct'] as int,
      consolidatedAt: now.subtract(age),
      flow: flow == null
          ? null
          : MockFlow(
              entries: flow['entries'] as int,
              exits: flow['exits'] as int,
              windowMin: flow['windowMin'] as int,
            ),
      consoleUnavailable:
          (console?['unavailable'] as List<dynamic>?)?.cast<String>() ??
          const [],
      forecast: _buildForecast(raw['forecast'] as Map<String, dynamic>),
      zones: [
        for (final zone in raw['zones'] as List<dynamic>)
          _buildZone(zone as Map<String, dynamic>),
      ],
    );
  }

  MockZone _buildZone(Map<String, dynamic> raw) {
    return MockZone(
      id: raw['id'] as int,
      name: raw['name'] as String,
      description: raw['description'] as String?,
      levels: [
        for (final level in raw['levels'] as List<dynamic>)
          _buildLevel(level as Map<String, dynamic>),
      ],
    );
  }

  MockLevel _buildLevel(Map<String, dynamic> raw) {
    final levelId = raw['id'] as int;
    return MockLevel(
      id: levelId,
      name: raw['name'] as String,
      spaces: [
        for (final space in raw['spaces'] as List<dynamic>)
          MockSpace(
            id: (space as Map<String, dynamic>)['id'] as int,
            levelId: levelId,
            label: space['label'] as String,
            posX: (space['posX'] as num).toDouble(),
            posY: (space['posY'] as num).toDouble(),
            status: space['status'] as String,
            unknownReason: space['unknownReason'] as String?,
          ),
      ],
    );
  }

  MockForecastSeed _buildForecast(Map<String, dynamic> raw) {
    final next = raw['nextAvailability'] as Map<String, dynamic>?;
    return MockForecastSeed(
      method: raw['method'] as String,
      confidenceByHorizon: {
        for (final entry
            in (raw['confidenceByHorizon'] as Map<String, dynamic>).entries)
          int.parse(entry.key): (entry.value as num).toDouble(),
      },
      saturationInMinutes: raw['saturationInMinutes'] as int?,
      nextAvailability: next == null
          ? null
          : MockNextAvailability(
              minMinutes: next['minMinutes'] as int,
              maxMinutes: next['maxMinutes'] as int,
              confidence: (next['confidence'] as num).toDouble(),
            ),
    );
  }
}

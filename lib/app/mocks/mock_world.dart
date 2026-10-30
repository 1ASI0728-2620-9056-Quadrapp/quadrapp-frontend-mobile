import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:quadrapp_mobile/app/mocks/iam/mock_iam_state.dart';
import 'package:quadrapp_mobile/app/mocks/mock_controls.dart';
import 'package:quadrapp_mobile/app/mocks/mock_devices.dart';
import 'package:quadrapp_mobile/app/mocks/mock_errors.dart';
import 'package:quadrapp_mobile/app/mocks/mock_lots.dart';
import 'package:quadrapp_mobile/app/mocks/mock_seed.dart';
import 'package:quadrapp_mobile/app/mocks/notifications/mock_notifications_state.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';

export 'package:quadrapp_mobile/app/mocks/mock_devices.dart';
export 'package:quadrapp_mobile/app/mocks/mock_lots.dart';

/// Un cambio de estado de un espacio (lo que envía el WebSocket).
class MockSpaceEvent {
  const MockSpaceEvent({
    required this.lotId,
    required this.eventId,
    required this.spaceId,
    required this.status,
    required this.at,
  });

  final int lotId;
  final String eventId;
  final int spaceId;
  final String status;
  final DateTime at;

  Map<String, Object?> toJson() => {
    'eventId': eventId,
    'spaceId': spaceId,
    'status': status,
    'at': at.toUtc().toIso8601String(),
  };
}

/// Mundo en memoria coherente: estacionamientos, espacios y su simulador.
///
/// Todos los datasources mock leen de aquí, así lo que muestra la ocupación es
/// consistente con lo que muestran los pronósticos y las suscripciones.
///
/// - Los datos de partida salen de [seed] (`assets/mocks/seed.json`): cuatro
///   estacionamientos (uno normal, uno casi lleno, uno sin distribución
///   publicada y uno con el dato vencido), los usuarios de prueba y las
///   suscripciones. [reset] vuelve a ellos.
/// - Un simulador con `Timer`: cada 3 a 8 s cambia el estado de un espacio de
///   los estacionamientos que la semilla marca como simulados; a veces un
///   sensor pasa a `UNKNOWN` por batería baja.
/// - Latencia simulada de 200 a 600 ms y los interruptores de [MockControls].
class MockWorld {
  MockWorld({
    required this.clock,
    required this.seed,
    MockControls? controls,
    Random? random,
    this.latency = true,
  }) : controls = controls ?? MockControls(),
       random = random ?? Random(7),
       iam = MockIamState(seed),
       notifications = MockNotificationsState(seed) {
    final now = clock.now();
    lots = seed.buildLots(now);
    devices = seed.buildDevices(now);
  }

  /// Los datos de prueba de partida.
  final MockSeed seed;

  /// El reloj del "servidor".
  final Clock clock;
  final MockControls controls;
  final Random random;

  /// Si es `true`, cada llamada espera de 200 a 600 ms.
  final bool latency;

  late List<MockLot> lots;

  /// El inventario de dispositivos de todos los estacionamientos.
  late List<MockDevice> devices;

  /// Códigos OTP, usuarios y sesiones (refresh tokens vigentes).
  final MockIamState iam;

  /// Suscripciones, preferencias y tokens de notificaciones.
  final MockNotificationsState notifications;

  final StreamController<MockSpaceEvent> _events =
      StreamController<MockSpaceEvent>.broadcast();
  Timer? _timer;
  int _eventCounter = 0;

  Stream<MockSpaceEvent> get events => _events.stream;

  MockLot? lot(int id) {
    for (final lot in lots) {
      if (lot.id == id) return lot;
    }
    return null;
  }

  Iterable<MockDevice> devicesOf(int lotId) =>
      devices.where((device) => device.lotId == lotId);

  /// ¿Ya hay un dispositivo con ese identificador físico? (es único, docs/06).
  bool hardwareIdTaken(String hardwareId) =>
      devices.any((device) => device.hardwareId == hardwareId);

  /// Registra un dispositivo operativo, sin espacio ni acceso asociado (US32
  /// esc. 1; asignarlo es de la consola web).
  MockDevice registerDevice({
    required int lotId,
    required String type,
    required String hardwareId,
    required int expectedReportIntervalSec,
    bool? directional,
  }) {
    final device = MockDevice(
      id: devices.fold(0, (top, d) => max(top, d.id)) + 1,
      lotId: lotId,
      hardwareId: hardwareId,
      type: type,
      status: 'OPERATIONAL',
      expectedReportIntervalSec: expectedReportIntervalSec,
      directional: directional,
    );
    devices.add(device);
    return device;
  }

  /// Da de baja un dispositivo (US32 esc. 3): deja de aceptar eventos y sigue
  /// en el inventario como `DECOMMISSIONED`. `false` si no existe.
  bool decommissionDevice(int id) {
    for (final device in devices) {
      if (device.id == id) {
        device.status = 'DECOMMISSIONED';
        return true;
      }
    }
    return false;
  }

  /// Aplica la latencia simulada y los errores forzados. Los mocks llaman a
  /// esto antes de responder. [isAuth] marca las llamadas de `/auth/*` (que no
  /// llevan token: allí aplica el 429 y no el 401). El 429 es de la solicitud
  /// del código: con [rateLimited] en `false` (login y refresh) no se aplica.
  Future<void> gate({bool isAuth = false, bool rateLimited = true}) async {
    if (latency) {
      await Future<void>.delayed(
        Duration(milliseconds: 200 + random.nextInt(401)),
      );
    }
    if (controls.forceNetworkError) {
      throw mockDioError(DioExceptionType.connectionError);
    }
    if (isAuth) {
      if (rateLimited && controls.force429) {
        throw mockHttpError(
          429,
          title: 'Too Many Requests',
          extra: {'retryAfterSec': 45},
        );
      }
    } else if (controls.force401) {
      throw mockHttpError(401, title: 'Unauthorized');
    }
  }

  /// Como [gate], para las rutas de consola (`/console/overview`, `/devices*`):
  /// solo las atiende un rol de Operación (`ADMIN` u `OPERATOR`); un conductor
  /// recibe 403 y no se le entrega nada (TS17 esc. 2). [callerRole] es el rol
  /// de quien llama (los mocks no pasan por el interceptor de red, así que el
  /// token real lo decide la composición); sin rol, 401.
  Future<void> gateConsole(String? callerRole) async {
    await gate();
    if (callerRole == null) throw mockHttpError(401, title: 'Unauthorized');
    final allowed = callerRole == 'ADMIN' || callerRole == 'OPERATOR';
    if (controls.forceConsole403 || !allowed) {
      throw mockHttpError(
        403,
        title: 'Forbidden',
        detail: 'Este rol no tiene acceso a la consola de operación.',
      );
    }
  }

  /// Arranca el simulador: un cambio cada 3 a 8 s.
  void startSimulator() {
    _timer?.cancel();
    _schedule();
  }

  void stopSimulator() {
    _timer?.cancel();
    _timer = null;
  }

  void _schedule() {
    _timer = Timer(Duration(seconds: 3 + random.nextInt(6)), () {
      tick();
      _schedule();
    });
  }

  /// Un cambio del simulador (público para poder probarlo sin esperar).
  MockSpaceEvent? tick() {
    final simulated = seed.simulatedLotIds;
    final active = lots
        .where((l) => l.hasLayout && simulated.contains(l.id))
        .toList();
    if (active.isEmpty) return null;
    // El primer estacionamiento cambia más que el último (el casi lleno).
    final lot = random.nextDouble() < 0.7 ? active.first : active.last;
    final space = lot.spaces.elementAt(random.nextInt(lot.capacity));

    final String next;
    if (space.status == 'UNKNOWN') {
      // Un sensor caído se recupera con el tiempo.
      if (random.nextDouble() < 0.5) return null;
      next = random.nextBool() ? 'FREE' : 'OCCUPIED';
    } else if (random.nextDouble() < 0.05) {
      next = 'UNKNOWN';
    } else if (space.status == 'OCCUPIED') {
      // Un estacionamiento saturado casi no libera espacios.
      final chance = lot.isSaturated ? 0.25 : 1.0;
      if (random.nextDouble() > chance) return null;
      next = 'FREE';
    } else {
      next = 'OCCUPIED';
    }
    return setSpaceStatus(
      lot,
      space,
      next,
      reason: next == 'UNKNOWN' ? 'LOW_BATTERY' : null,
    );
  }

  /// Cambia el estado de un espacio y emite el evento correspondiente.
  MockSpaceEvent setSpaceStatus(
    MockLot lot,
    MockSpace space,
    String status, {
    String? reason,
  }) {
    final at = clock.now();
    space
      ..status = status
      ..unknownReason = status == 'UNKNOWN' ? (reason ?? 'NO_HEARTBEAT') : null;
    lot.consolidatedAt = at;
    final event = MockSpaceEvent(
      lotId: lot.id,
      eventId: 'mock-${_eventCounter++}',
      spaceId: space.id,
      status: status,
      at: at,
    );
    _events.add(event);
    return event;
  }

  /// Vuelve a los datos de la semilla: espacios, dispositivos, antigüedad del
  /// dato, suscripciones y preferencias. Conserva las sesiones vigentes
  /// (refresh tokens) y los tokens de dispositivo, para no cerrar la sesión de
  /// quien está probando. No emite eventos: quien muestre datos debe
  /// recargarlos.
  void reset() {
    final now = clock.now();
    lots = seed.buildLots(now);
    devices = seed.buildDevices(now);
    notifications.loadSeed(seed);
    iam.resetCodes();
  }

  Future<void> dispose() async {
    stopSimulator();
    await _events.close();
  }
}

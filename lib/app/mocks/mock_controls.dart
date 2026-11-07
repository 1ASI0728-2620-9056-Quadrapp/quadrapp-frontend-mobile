import 'package:flutter/foundation.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/repositories/location_permission_gateway.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';

/// Interruptores para probar todos los estados de pantalla contra los mocks
/// (docs/07): errores de red, respuestas parciales, sesión expirada (401),
/// demasiados códigos (429) y un reloj del teléfono desfasado.
class MockControls {
  /// Toda llamada falla como si no hubiera red.
  bool forceNetworkError = false;

  /// Las llamadas autenticadas responden 401 (sesión expirada).
  bool force401 = false;

  /// La solicitud de código OTP responde 429 (demasiados códigos). Solo aplica
  /// a `POST /auth/otp`: el login y el refresh no se limitan.
  bool force429 = false;

  /// El refresh responde 401: el token de refresco venció o fue revocado, es
  /// decir, la sesión expiró (US03).
  bool sessionExpired = false;

  /// `GET /mobile/home` responde 200 pero sin una sección (`unavailable`).
  bool forcePartial = false;

  /// Horizontes (15, 30, 45, 60) sin pronóstico: `GET /forecasts` responde
  /// 404 para ellos (US10 esc. 2).
  Set<int> missingForecastHorizons = {};

  /// La próxima liberación responde `NO_EXITS` aunque haya historial (US36
  /// esc. 2).
  bool nextAvailabilityNoExits = false;

  /// Las rutas de consola (`/console/overview`, `/devices*`) responden 403
  /// aunque la sesión sea de Operación (TS17 esc. 2).
  bool forceConsole403 = false;

  /// `GET /console/overview` responde 200 pero sin la saturación prevista
  /// (`unavailable: ["saturation"]`, TS17 esc. 3).
  bool forceConsolePartial = false;

  /// `POST /devices` falla con un error del servidor (500).
  bool forceDeviceRegisterFailure = false;

  /// El `PushGateway` stub niega el permiso de notificaciones al pedirlo: la
  /// primera vez queda "denegado"; la segunda, "denegado para siempre", como
  /// en Android.
  bool denyPushPermission = false;

  /// El `PushGateway` stub no entrega un token aunque el permiso esté
  /// concedido.
  bool pushTokenUnavailable = false;

  /// La conexión en tiempo real (WebSocket) se cae y no se recupera mientras
  /// esté activo; las llamadas REST siguen funcionando. Es un [ValueNotifier]
  /// porque el mock del socket reacciona al instante: avisa
  /// `RealtimeDisconnected` al activarlo y `RealtimeConnected` al apagarlo, y
  /// el chip "Live" de Inicio pasa a "Reconnecting".
  final ValueNotifier<bool> realtimeOutage = ValueNotifier<bool>(false);

  /// El permiso de ubicación del teléfono simulado. Parte concedido (el ETA
  /// automático se ve desde el primer arranque); con `denied` se prueba la
  /// explicación previa y el modo manual.
  LocationPermissionStatus locationPermission =
      LocationPermissionStatus.granted;

  /// Al pedir el permiso, el diálogo del sistema lo niega: la primera vez
  /// queda `denied` y la segunda, `deniedForever`.
  bool denyLocationPrompt = false;

  /// Cuántas veces se negó el permiso al pedirlo.
  int locationPromptDenials = 0;

  /// El teléfono simulado va manejando hacia la sede elegida (150 km/h: un
  /// viaje de minutos), así el ETA baja solo y se ve cómo se actualiza la
  /// asesoría.
  bool simulateTrip = false;

  /// Cuando está encendido, el proveedor de mapas simulado devuelve un viaje
  /// con mucho tráfico (×1,8 en lugar de ×1,3).
  bool heavyTraffic = false;

  /// El proveedor de mapas simulado no responde: la app cae a la estimación
  /// local sin mostrar un error.
  bool routesOutage = false;

  /// Cuánto se adelanta (o atrasa) el reloj del teléfono respecto del
  /// servidor: sirve para comprobar que la antigüedad no depende de él.
  Duration phoneClockSkew = Duration.zero;
}

/// Reloj del "teléfono" para los mocks: la hora de pared se desfasa con
/// [MockControls.phoneClockSkew]; el reloj monótono no.
class MockPhoneClock implements Clock {
  const MockPhoneClock(this._base, this._controls);

  final Clock _base;
  final MockControls _controls;

  @override
  DateTime now() => _base.now().add(_controls.phoneClockSkew);

  @override
  Duration monotonic() => _base.monotonic();
}

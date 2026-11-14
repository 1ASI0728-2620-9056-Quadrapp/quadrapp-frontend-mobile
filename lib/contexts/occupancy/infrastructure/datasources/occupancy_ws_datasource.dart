import 'dart:async';
import 'dart:convert';

import 'package:quadrapp_mobile/contexts/occupancy/infrastructure/datasources/occupancy_realtime_datasource.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/logging/logger.dart';
import 'package:quadrapp_mobile/core/network/stomp_frame.dart';
import 'package:quadrapp_mobile/core/network/web_socket_connector.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Espera antes del intento número [attempt] (0, 1, 2...): 1 s, 2 s, 4 s...
/// con un tope de 30 s.
Duration exponentialBackoff(int attempt) {
  final seconds = 1 << attempt.clamp(0, 5);
  return Duration(seconds: seconds > 30 ? 30 : seconds);
}

/// Ocupación en tiempo real por STOMP sobre el WebSocket `/ws` del backend.
///
/// - El token va en el frame `CONNECT` (`Authorization: Bearer …`), no en la
///   conexión: así lo pide `StompAuthorizationInterceptor`.
/// - Tras `CONNECTED` se suscribe a `/topic/parking-lots/{lotId}/occupancy`
///   y avisa [RealtimeConnected].
/// - Cada `MESSAGE` trae los conteos de la zona y del estacionamiento que
///   cambiaron; el backend no expone por REST el estado de cada espacio, así
///   que se avisa [RealtimeCountsChanged] y el repositorio vuelve a pedir el
///   estado completo.
/// - Un `ERROR` (token vencido, estacionamiento ajeno) o un corte avisa
///   [RealtimeDisconnected] y reintenta con espera exponencial y tope, leyendo
///   el token otra vez.
/// - Manda un latido (salto de línea) cada [keepAlive] para que un proxy no
///   cierre la conexión inactiva.
class OccupancyWsDataSource implements OccupancyRealtimeDataSource {
  OccupancyWsDataSource({
    required this._connector,
    required this._url,
    required this._accessToken,
    required this._logger,
    this._backoff = exponentialBackoff,
    this._delay = _defaultDelay,
    this.keepAlive = const Duration(seconds: 20),
  });

  final WebSocketConnector _connector;
  final Uri _url;
  final String? Function() _accessToken;
  final Logger _logger;
  final Duration Function(int attempt) _backoff;
  final Future<void> Function(Duration duration) _delay;
  final Duration keepAlive;

  static Future<void> _defaultDelay(Duration duration) =>
      Future<void>.delayed(duration);

  /// El tópico de ocupación de [lotId].
  static String topicFor(LotId lotId) =>
      '/topic/parking-lots/${lotId.value}/occupancy';

  @override
  Stream<OccupancyRealtimeEvent> connect(LotId lotId) {
    var closed = false;
    WebSocketChannel? channel;
    Timer? heartbeat;
    late final StreamController<OccupancyRealtimeEvent> controller;

    Future<void> run() async {
      var attempt = 0;
      while (!closed) {
        try {
          channel = _connector.connect(_url);
          await channel!.ready;
          if (closed) break;
          final token = _accessToken();
          channel!.sink.add(
            StompFrame(
              'CONNECT',
              headers: {
                'accept-version': '1.2',
                'host': _url.host,
                'heart-beat': '0,0',
                if (token != null) 'Authorization': 'Bearer $token',
              },
            ).encode(),
          );
          await for (final message in channel!.stream) {
            if (message is! String) continue;
            for (final frame in StompFrame.decodeAll(message)) {
              switch (frame.command) {
                case 'CONNECTED':
                  channel!.sink.add(
                    StompFrame(
                      'SUBSCRIBE',
                      headers: {
                        'id': 'occupancy-${lotId.value}',
                        'destination': topicFor(lotId),
                      },
                    ).encode(),
                  );
                  attempt = 0;
                  heartbeat?.cancel();
                  heartbeat = Timer.periodic(
                    keepAlive,
                    (_) => channel?.sink.add('\n'),
                  );
                  controller.add(const RealtimeConnected());
                case 'MESSAGE':
                  if (_isCountsMessage(frame.body)) {
                    controller.add(const RealtimeCountsChanged());
                  }
                case 'ERROR':
                  throw StateError('STOMP ERROR: ${frame.headers['message']}');
              }
            }
          }
        } on Object catch (error) {
          _logger.warning(
            'STOMP de ocupación: conexión fallida',
            error: error.runtimeType,
          );
        } finally {
          heartbeat?.cancel();
          unawaited(channel?.sink.close() ?? Future<void>.value());
        }
        if (closed) break;
        controller.add(const RealtimeDisconnected());
        await _delay(_backoff(attempt++));
      }
      await controller.close();
    }

    controller = StreamController<OccupancyRealtimeEvent>(
      onListen: () => unawaited(run()),
      onCancel: () {
        closed = true;
        heartbeat?.cancel();
        unawaited(channel?.sink.close() ?? Future<void>.value());
      },
    );
    return controller.stream;
  }

  /// `OccupancyRealtimeMessage` del backend: un objeto con los conteos del
  /// estacionamiento. Un mensaje ilegible se descarta sin cerrar la conexión.
  bool _isCountsMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> &&
          decoded['parkingLot'] is Map<String, dynamic>) {
        return true;
      }
    } on FormatException {
      // Se registra abajo.
    }
    _logger.warning('STOMP de ocupación: mensaje ilegible descartado');
    return false;
  }
}

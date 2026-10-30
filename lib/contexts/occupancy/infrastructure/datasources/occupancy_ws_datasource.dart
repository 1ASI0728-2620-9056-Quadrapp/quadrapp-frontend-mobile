import 'dart:async';
import 'dart:convert';

import 'package:quadrapp_mobile/contexts/occupancy/infrastructure/datasources/occupancy_realtime_datasource.dart';
import 'package:quadrapp_mobile/contexts/occupancy/infrastructure/dto/space_change_dto.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/logging/logger.dart';
import 'package:quadrapp_mobile/core/network/web_socket_connector.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Espera antes del intento número [attempt] (0, 1, 2...): 1 s, 2 s, 4 s...
/// con un tope de 30 s.
Duration exponentialBackoff(int attempt) {
  final seconds = 1 << attempt.clamp(0, 5);
  return Duration(seconds: seconds > 30 ? 30 : seconds);
}

/// WebSocket `/ws/parking-lots/{lotId}` con `web_socket_channel`. La
/// autenticación va por cabecera. Reconecta con espera exponencial y tope;
/// avisa cada conexión y desconexión para que el repositorio vuelva a pedir el
/// estado completo.
class OccupancyWsDataSource implements OccupancyRealtimeDataSource {
  OccupancyWsDataSource({
    required this._connector,
    required this._urlFor,
    required this._accessToken,
    required this._logger,
    this._backoff = exponentialBackoff,
    this._delay = _defaultDelay,
  });

  final WebSocketConnector _connector;
  final Uri Function(LotId lotId) _urlFor;
  final String? Function() _accessToken;
  final Logger _logger;
  final Duration Function(int attempt) _backoff;
  final Future<void> Function(Duration duration) _delay;

  static Future<void> _defaultDelay(Duration duration) =>
      Future<void>.delayed(duration);

  @override
  Stream<OccupancyRealtimeEvent> connect(LotId lotId) {
    var closed = false;
    WebSocketChannel? channel;
    late final StreamController<OccupancyRealtimeEvent> controller;

    Future<void> run() async {
      var attempt = 0;
      while (!closed) {
        try {
          final token = _accessToken();
          channel = _connector.connect(
            _urlFor(lotId),
            headers: {if (token != null) 'Authorization': 'Bearer $token'},
          );
          await channel!.ready;
          if (closed) break;
          attempt = 0;
          controller.add(const RealtimeConnected());
          await for (final message in channel!.stream) {
            final change = _parse(message);
            if (change != null) controller.add(RealtimeChange(change));
          }
        } on Object catch (error) {
          _logger.warning(
            'WebSocket de ocupación: conexión fallida',
            error: error.runtimeType,
          );
        } finally {
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
        unawaited(channel?.sink.close() ?? Future<void>.value());
      },
    );
    return controller.stream;
  }

  /// Un mensaje ilegible se descarta sin cerrar la conexión.
  SpaceChangeDto? _parse(Object? message) {
    try {
      final decoded = message is String ? jsonDecode(message) : message;
      if (decoded is! Map<String, dynamic>) return null;
      return SpaceChangeDto.fromJson(decoded);
    } on Object {
      _logger.warning('WebSocket de ocupación: mensaje ilegible descartado');
      return null;
    }
  }
}

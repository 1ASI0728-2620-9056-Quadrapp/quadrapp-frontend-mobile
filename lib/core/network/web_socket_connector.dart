import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Abre canales WebSocket. Detrás de una abstracción para poder probar sin red.
// ignore: one_member_abstracts
abstract interface class WebSocketConnector {
  WebSocketChannel connect(Uri uri, {Map<String, String> headers});
}

/// Conector real: la autenticación va por cabecera.
class IoWebSocketConnector implements WebSocketConnector {
  const IoWebSocketConnector();

  @override
  WebSocketChannel connect(
    Uri uri, {
    Map<String, String> headers = const {},
  }) => IOWebSocketChannel.connect(uri, headers: headers);
}

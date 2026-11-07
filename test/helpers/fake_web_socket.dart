import 'dart:async';

import 'package:quadrapp_mobile/core/network/web_socket_connector.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Canal WebSocket falso: los mensajes se emiten a mano con [emit] y la
/// conexión se corta con [drop].
class FakeWebSocketChannel extends StreamChannelMixin<dynamic>
    implements WebSocketChannel {
  FakeWebSocketChannel({this.readyError});

  /// Si no es nulo, `ready` falla con este error (el servidor no responde).
  final Object? readyError;

  final StreamController<dynamic> _incoming = StreamController<dynamic>();
  final _FakeSink _sink = _FakeSink();

  @override
  Future<void> get ready => readyError == null
      ? Future<void>.value()
      : Future<void>.error(readyError!);

  bool get isClosedByClient => _sink.closed;

  void emit(Object message) => _incoming.add(message);

  Future<void> drop() => _incoming.close();

  @override
  Stream<dynamic> get stream => _incoming.stream;

  @override
  WebSocketSink get sink => _sink;

  @override
  String? get protocol => null;

  @override
  int? get closeCode => null;

  @override
  String? get closeReason => null;
}

class _FakeSink implements WebSocketSink {
  bool closed = false;
  final Completer<void> _done = Completer<void>();

  @override
  void add(dynamic data) {}

  @override
  void addError(Object error, [StackTrace? stackTrace]) {}

  @override
  Future<void> addStream(Stream<dynamic> stream) async {}

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    closed = true;
    if (!_done.isCompleted) _done.complete();
  }

  @override
  Future<void> get done => _done.future;
}

/// Conector falso: entrega los canales en orden y guarda a qué se conectó.
class FakeWebSocketConnector implements WebSocketConnector {
  FakeWebSocketConnector(this._channels);

  final List<WebSocketChannel> _channels;
  final List<Uri> uris = [];
  final List<Map<String, String>> headers = [];

  @override
  WebSocketChannel connect(Uri uri, {Map<String, String> headers = const {}}) {
    uris.add(uri);
    this.headers.add(headers);
    return _channels.removeAt(0);
  }
}

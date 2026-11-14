/// Un frame STOMP 1.2 (lo justo para suscribirse a un tópico del backend):
/// comando, cabeceras y cuerpo de texto.
class StompFrame {
  const StompFrame(this.command, {this.headers = const {}, this.body = ''});

  final String command;
  final Map<String, String> headers;
  final String body;

  /// El frame listo para enviar, terminado en NUL.
  String encode() {
    final buffer = StringBuffer('$command\n');
    headers.forEach((name, value) => buffer.write('$name:$value\n'));
    buffer
      ..write('\n')
      ..write(body)
      ..write('\u0000');
    return buffer.toString();
  }

  /// Lee los frames de un mensaje del WebSocket. Los saltos de línea sueltos
  /// (latidos) se ignoran; un texto sin comando no produce frames.
  static List<StompFrame> decodeAll(String message) {
    final frames = <StompFrame>[];
    for (final raw in message.split('\u0000')) {
      final text = raw.replaceFirst(RegExp(r'^[\r\n]+'), '');
      if (text.isEmpty) continue;
      final split = text.indexOf('\n\n');
      final head = (split < 0 ? text : text.substring(0, split)).split('\n');
      final body = split < 0 ? '' : text.substring(split + 2);
      final headers = <String, String>{};
      for (final line in head.skip(1)) {
        final colon = line.indexOf(':');
        if (colon <= 0) continue;
        // STOMP 1.2: si una cabecera se repite, vale la primera.
        headers.putIfAbsent(
          line.substring(0, colon),
          () => line.substring(colon + 1).replaceAll('\r', ''),
        );
      }
      frames.add(
        StompFrame(head.first.trim(), headers: headers, body: body),
      );
    }
    return frames;
  }
}

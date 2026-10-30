import 'package:quadrapp_mobile/core/logging/logger.dart';

/// Logger que guarda los avisos, para comprobar qué se registra.
class RecordingLogger implements Logger {
  final List<String> messages = [];

  @override
  void warning(String message, {Object? error}) => messages.add(message);
}

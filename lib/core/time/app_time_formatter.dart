import 'package:intl/intl.dart';

/// Único lugar que conoce la zona horaria de la app: `America/Lima`.
///
/// Las fechas del dominio son `DateTime` en UTC y solo se convierten aquí. Lima
/// está en UTC−5 sin horario de verano, así que se usa un desfase fijo, sin un
/// paquete de zonas horarias. Si la regla cambia, solo se modifica este
/// archivo.
class AppTimeFormatter {
  const AppTimeFormatter();

  /// Desfase de Lima respecto de UTC.
  static const Duration limaOffset = Duration(hours: -5);

  /// La hora de pared de Lima como un `DateTime` "sin zona" (marcado UTC solo
  /// para que `intl` no lo vuelva a convertir).
  DateTime toLima(DateTime instant) => instant.toUtc().add(limaOffset);

  /// Hora del día, por ejemplo "8:42 AM" o "8:42".
  String formatTime(DateTime instant, String locale) =>
      DateFormat.jm(locale).format(toLima(instant));

  /// Fecha y hora, por ejemplo "Sep 28, 8:42 AM".
  String formatDateTime(DateTime instant, String locale) =>
      DateFormat.MMMd(locale).add_jm().format(toLima(instant));

  /// Cuenta regresiva como minutos y segundos ("0:45", "1:05"). Los segundos
  /// se redondean hacia arriba: nunca muestra "0:00" mientras queda tiempo.
  String formatCountdown(Duration remaining) {
    final total = remaining.isNegative
        ? 0
        : (remaining.inMilliseconds / 1000).ceil();
    final minutes = total ~/ 60;
    final seconds = (total % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

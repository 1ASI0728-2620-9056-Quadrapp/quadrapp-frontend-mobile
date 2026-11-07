// US33
import 'package:intl/intl.dart';
import 'package:quadrapp_mobile/contexts/notifications/notifications.dart';

String _capitalized(String text) =>
    text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

/// Los nombres de los días de lunes (1) a domingo (7) en [locale], con
/// mayúscula inicial: cortos («Lun») o completos («Lunes»).
List<String> weekdayNames(String locale, {required bool short}) {
  final symbols = DateFormat.E(locale).dateSymbols;
  final sundayFirst = short ? symbols.SHORTWEEKDAYS : symbols.WEEKDAYS;
  return [
    for (final name in [...sundayFirst.sublist(1), sundayFirst.first])
      _capitalized(name),
  ];
}

/// Los días de una franja, de forma corta: una racha de tres o más días
/// seguidos se resume («Lun–Vie»); el resto, separados por comas («Lun, Mié»).
String daysLabel(Iterable<AlertDay> days, String locale) {
  final names = weekdayNames(locale, short: true);
  final numbers = ({for (final day in days) day.isoNumber}.toList())..sort();
  final parts = <String>[];
  var i = 0;
  while (i < numbers.length) {
    var j = i;
    while (j + 1 < numbers.length && numbers[j + 1] == numbers[j] + 1) {
      j++;
    }
    final first = names[numbers[i] - 1];
    final last = names[numbers[j] - 1];
    if (j - i >= 2) {
      parts.add('$first–$last');
    } else {
      for (var k = i; k <= j; k++) {
        parts.add(names[numbers[k] - 1]);
      }
    }
    i = j + 1;
  }
  return parts.join(', ');
}

/// Una hora de reloj de Lima (la de una franja), con el formato del idioma:
/// «7:30 AM» o «7:30 a. m.».
String clockLabel(ClockTime time, String locale) =>
    DateFormat.jm(locale).format(DateTime(2000, 1, 1, time.hour, time.minute));

/// El rango de una franja: «7:30 AM – 9:00 AM».
String slotLabel(AlertTimeSlot slot, String locale) =>
    '${clockLabel(slot.from, locale)} – ${clockLabel(slot.to, locale)}';

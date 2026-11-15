// US33: cómo se dicen los días y la hora de una franja.
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:quadrapp_mobile/composition/alerts/alert_format.dart';
import 'package:quadrapp_mobile/contexts/notifications/notifications.dart';

import 'support.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('es');
  });

  const workdays = [
    AlertDay.monday,
    AlertDay.tuesday,
    AlertDay.wednesday,
    AlertDay.thursday,
    AlertDay.friday,
  ];

  group('daysLabel', () {
    test('una racha de tres o más días se resume', () {
      expect(daysLabel(workdays, 'en'), 'Mon–Fri');
      expect(daysLabel(workdays, 'es'), 'Lun–Vie');
      expect(daysLabel(AlertDay.values, 'en'), 'Mon–Sun');
    });

    test('los días sueltos van separados por comas', () {
      expect(
        daysLabel(
          const [AlertDay.monday, AlertDay.wednesday, AlertDay.friday],
          'en',
        ),
        'Mon, Wed, Fri',
      );
      // Dos días seguidos no son una racha.
      expect(
        daysLabel(const [AlertDay.saturday, AlertDay.sunday], 'en'),
        'Sat, Sun',
      );
    });

    test('una racha y días sueltos se combinan, sin importar el orden', () {
      expect(
        daysLabel(
          const [
            AlertDay.friday,
            AlertDay.wednesday,
            AlertDay.monday,
            AlertDay.tuesday,
          ],
          'es',
        ),
        'Lun–Mié, Vie',
      );
    });
  });

  group('horas', () {
    test('la hora sigue el formato del idioma', () {
      expect(clockLabel(time(7, 30), 'en').replaceAll(' ', ' '), '7:30 AM');
      // En español la hora va en formato de 24 horas.
      expect(clockLabel(time(13, 5), 'es'), '13:05');
    });

    test('el rango junta el inicio y el fin', () {
      final slot = subscription().slot;

      expect(
        slotLabel(slot, 'en').replaceAll(' ', ' '),
        '7:30 AM – 9:00 AM',
      );
    });
  });

  test('los nombres de los días van de lunes a domingo, con mayúscula', () {
    expect(weekdayNames('en', short: true), [
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ]);
    expect(weekdayNames('es', short: false).first, 'Lunes');
    expect(weekdayNames('es', short: false).last, 'Domingo');
  });
}

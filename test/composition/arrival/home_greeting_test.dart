// Saludo de Inicio (adición fuera de las historias): parte del día, primer
// nombre e iniciales.
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/composition/arrival/home_greeting.dart';

void main() {
  group('greetingPeriodFor', () {
    test('mañana de 5:00 a 11:59, tarde de 12:00 a 18:59, noche el resto', () {
      expect(greetingPeriodFor(4), GreetingPeriod.evening);
      expect(greetingPeriodFor(5), GreetingPeriod.morning);
      expect(greetingPeriodFor(11), GreetingPeriod.morning);
      expect(greetingPeriodFor(12), GreetingPeriod.afternoon);
      expect(greetingPeriodFor(18), GreetingPeriod.afternoon);
      expect(greetingPeriodFor(19), GreetingPeriod.evening);
      expect(greetingPeriodFor(0), GreetingPeriod.evening);
    });
  });

  group('firstNameOf', () {
    test('la primera palabra del nombre completo', () {
      expect(firstNameOf('Camila Rojas'), 'Camila');
      expect(firstNameOf('  María   José Pérez '), 'María');
    });

    test('sin nombre (nulo o vacío) no hay nombre', () {
      expect(firstNameOf(null), isNull);
      expect(firstNameOf('   '), isNull);
    });
  });

  group('initialsOf', () {
    test('primera y última palabra, en mayúscula', () {
      expect(initialsOf('Camila Rojas'), 'CR');
      expect(initialsOf('maría josé pérez'), 'MP');
    });

    test('una sola palabra da una letra; sin nombre, nada', () {
      expect(initialsOf('Camila'), 'C');
      expect(initialsOf(null), isNull);
      expect(initialsOf(''), isNull);
    });
  });
}

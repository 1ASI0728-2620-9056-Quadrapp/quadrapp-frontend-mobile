// US01 (esc. 2): el correo se muestra sin su parte local.
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/contexts/iam/presentation/widgets/masked_email.dart';

void main() {
  group('maskEmail', () {
    test('deja la primera letra y el dominio', () {
      expect(maskEmail('camila.rojas@upc.edu.pe'), 'c•••@upc.edu.pe');
      expect(maskEmail('a@upc.edu.pe'), 'a•••@upc.edu.pe');
    });

    test('lo que no es un correo se devuelve igual', () {
      expect(maskEmail('sin-arroba'), 'sin-arroba');
      expect(maskEmail('@upc.edu.pe'), '@upc.edu.pe');
      expect(maskEmail(''), '');
    });

    test('usa la primera letra entera aunque no sea ASCII', () {
      expect(maskEmail('ñandú@upc.edu.pe'), 'ñ•••@upc.edu.pe');
    });
  });

  group('emailHint', () {
    test('separa la primera letra y el dominio para decirlos en voz alta', () {
      final hint = emailHint('camila.rojas@upc.edu.pe');

      expect(hint.first, 'c');
      expect(hint.domain, 'upc.edu.pe');
    });
  });
}

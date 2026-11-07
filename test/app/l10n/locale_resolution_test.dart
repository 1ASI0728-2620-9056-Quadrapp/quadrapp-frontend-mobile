import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/app/l10n/locale_resolution.dart';

void main() {
  group('resolveLocale', () {
    test('sin preferencia usa inglés', () {
      expect(resolveLocale(null), const Locale('en'));
    });

    test('respeta la preferencia en español o en inglés', () {
      expect(resolveLocale(const Locale('es')), const Locale('es'));
      expect(resolveLocale(const Locale('en')), const Locale('en'));
    });

    test('normaliza la región al idioma soportado', () {
      expect(resolveLocale(const Locale('es', 'PE')), const Locale('es'));
      expect(resolveLocale(const Locale('en', 'GB')), const Locale('en'));
    });

    test('un idioma no soportado usa inglés', () {
      expect(resolveLocale(const Locale('fr')), const Locale('en'));
      expect(resolveLocale(const Locale('pt', 'BR')), const Locale('en'));
    });
  });
}

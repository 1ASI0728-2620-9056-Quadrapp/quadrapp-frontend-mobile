
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

    test('ignora otras regiones cuando el idioma está soportado', () {
      expect(resolveLocale(const Locale('es', 'MX')), const Locale('es'));
      expect(resolveLocale(const Locale('en', 'US')), const Locale('en'));
    });

    test('un idioma no soportado usa inglés', () {
      expect(resolveLocale(const Locale('fr')), const Locale('en'));
      expect(resolveLocale(const Locale('pt', 'BR')), const Locale('en'));
    });

    test('idiomas no soportados con región usan inglés', () {
      expect(resolveLocale(const Locale('fr', 'FR')), const Locale('en'));
      expect(resolveLocale(const Locale('de', 'DE')), const Locale('en'));
    });
  });
}

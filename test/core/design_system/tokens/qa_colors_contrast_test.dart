import 'dart:math';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_colors.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_tone.dart';

/// Relación de contraste WCAG entre dos colores opacos.
double contrastRatio(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

const _text = 4.5;
const _graphic = 3.0;

typedef _Pair = ({
  String name,
  Color Function(QaColors) fg,
  Color Function(QaColors) bg,
  double min,
});

_Pair _p(
  String name,
  Color Function(QaColors) fg,
  Color Function(QaColors) bg,
  double min,
) => (name: name, fg: fg, bg: bg, min: min);

/// Cada combinación de la paleta que la app usa, con su mínimo WCAG.
final List<_Pair> _pairs = [
  // Sobre las tres superficies: texto (4.5:1) y componentes gráficos (3:1).
  for (final bg in <(String, Color Function(QaColors))>[
    ('background', (c) => c.background),
    ('surface', (c) => c.surface),
    ('surfaceMuted', (c) => c.surfaceMuted),
  ]) ...[
    _p('onSurface / ${bg.$1}', (c) => c.onSurface, bg.$2, _text),
    _p('onSurfaceMuted / ${bg.$1}', (c) => c.onSurfaceMuted, bg.$2, _text),
    _p('free (texto) / ${bg.$1}', (c) => c.free, bg.$2, _text),
    _p('limitedText / ${bg.$1}', (c) => c.limitedText, bg.$2, _text),
    _p('full (texto) / ${bg.$1}', (c) => c.full, bg.$2, _text),
    _p('occupied (texto) / ${bg.$1}', (c) => c.occupied, bg.$2, _text),
    _p('outline / ${bg.$1}', (c) => c.outline, bg.$2, _graphic),
    _p('primary (gráfico) / ${bg.$1}', (c) => c.primary, bg.$2, _graphic),
    _p('freeGraphic / ${bg.$1}', (c) => c.freeGraphic, bg.$2, _graphic),
    _p('limited (gráfico) / ${bg.$1}', (c) => c.limited, bg.$2, _graphic),
    _p('unknown (gráfico) / ${bg.$1}', (c) => c.unknown, bg.$2, _graphic),
    _p('full (gráfico) / ${bg.$1}', (c) => c.full, bg.$2, _graphic),
    _p('occupied (gráfico) / ${bg.$1}', (c) => c.occupied, bg.$2, _graphic),
  ],
  // El texto de acción (enlaces) va sobre el fondo y sobre la superficie.
  _p(
    'primary (texto) / background',
    (c) => c.primary,
    (c) => c.background,
    _text,
  ),
  _p('primary (texto) / surface', (c) => c.primary, (c) => c.surface, _text),
  // El texto atenuado también sobre cada fondo suave (4.5:1).
  for (final bg in <(String, Color Function(QaColors))>[
    ('mint', (c) => c.mint),
    ('primaryContainer', (c) => c.primaryContainer),
    ('freeFill', (c) => c.freeFill),
    ('limitedFill', (c) => c.limitedFill),
    ('alertFill', (c) => c.alertFill),
    ('occupiedFill', (c) => c.occupiedFill),
    ('infoFill', (c) => c.infoFill),
  ])
    _p('onSurfaceMuted / ${bg.$1}', (c) => c.onSurfaceMuted, bg.$2, _text),
  // Texto sobre los fondos suaves.
  _p('onMint / mint', (c) => c.onMint, (c) => c.mint, _text),
  _p('free / mint', (c) => c.free, (c) => c.mint, _text),
  _p('onSurface / infoFill', (c) => c.onSurface, (c) => c.infoFill, _text),
  _p(
    'onPrimaryContainer / primaryContainer',
    (c) => c.onPrimaryContainer,
    (c) => c.primaryContainer,
    _text,
  ),
  // Texto sobre rellenos fuertes.
  _p('onPrimary / primary', (c) => c.onPrimary, (c) => c.primary, _text),
  _p(
    'onPrimary / primaryDark',
    (c) => c.onPrimary,
    (c) => c.primaryDark,
    _text,
  ),
  _p('onAccent / full', (c) => c.onAccent, (c) => c.full, _text),
  _p('onAccent / occupied', (c) => c.onAccent, (c) => c.occupied, _text),
  // Marca: el héroe lleva texto blanco, texto atenuado y un detalle de acento.
  _p('onBrand / brand', (c) => c.onBrand, (c) => c.brand, _text),
  _p('onBrand / brandEnd', (c) => c.onBrand, (c) => c.brandEnd, _text),
  _p('onBrandMuted / brand', (c) => c.onBrandMuted, (c) => c.brand, _text),
  _p(
    'onBrandAccent / brandAccent',
    (c) => c.onBrandAccent,
    (c) => c.brandAccent,
    _text,
  ),
  _p(
    'brandAccent (plaza) / brand',
    (c) => c.brandAccent,
    (c) => c.brand,
    _graphic,
  ),
];

void main() {
  final palettes = <String, QaColors>{
    'claro': QaColors.light,
    'oscuro': QaColors.dark,
  };

  for (final MapEntry(key: mode, value: colors) in palettes.entries) {
    group('contraste en modo $mode', () {
      for (final pair in _pairs) {
        test('${pair.name} >= ${pair.min}:1', () {
          final ratio = contrastRatio(pair.fg(colors), pair.bg(colors));

          expect(
            ratio,
            greaterThanOrEqualTo(pair.min),
            reason: '${pair.name}: ${ratio.toStringAsFixed(2)}:1',
          );
        });
      }

      test('cada tono tiene texto legible sobre su fondo suave y color de '
          'acento sobre la superficie', () {
        for (final tone in QaTone.values) {
          expect(
            contrastRatio(colors.onFill(tone), colors.fill(tone)),
            greaterThanOrEqualTo(_text),
            reason: 'onFill/fill de $tone',
          );
          expect(
            contrastRatio(colors.accent(tone), colors.surface),
            greaterThanOrEqualTo(_text),
            reason: 'accent de $tone sobre surface',
          );
          expect(
            contrastRatio(colors.graphic(tone), colors.surface),
            greaterThanOrEqualTo(_graphic),
            reason: 'graphic de $tone sobre surface',
          );
        }
      });
    });
  }

  // Los colores del Figma que NO pasan AA tal cual y se ajustaron. Cada
  // desviación está en docs/05; estas pruebas prueban que el ajuste hacía
  // falta y que el color nuevo sí pasa.
  group('desviaciones del diseño por contraste', () {
    const white = Color(0xFFFFFFFF);
    const light = QaColors.light;

    test('el gris de pie y de pestañas (#789098) no sirve como texto', () {
      expect(contrastRatio(const Color(0xFF789098), white), lessThan(_text));
      expect(contrastRatio(light.onSurfaceMuted, white), greaterThan(_text));
    });

    test('el ámbar #D98617 no sirve ni como texto ni como gráfico sobre '
        'blanco', () {
      const amber = Color(0xFFD98617);
      expect(contrastRatio(amber, white), lessThan(_graphic));
      expect(contrastRatio(light.limitedText, white), greaterThan(_text));
      expect(contrastRatio(light.limited, white), greaterThan(_graphic));
    });

    test('el teal #087F83 no sirve como texto sobre el fondo', () {
      const teal = Color(0xFF087F83);
      expect(contrastRatio(teal, light.background), lessThan(_text));
      expect(
        contrastRatio(light.primary, light.background),
        greaterThan(_text),
      );
    });

    test(
      'el borde de campo del diseño (#D8E3E2) no es un borde de control',
      () {
        expect(contrastRatio(light.paint, white), lessThan(_graphic));
        expect(contrastRatio(light.outline, white), greaterThan(_graphic));
      },
    );

    test('el atenuado #59717A no pasa sobre los fondos suaves', () {
      const muted = Color(0xFF59717A);
      expect(contrastRatio(muted, light.mint), lessThan(_text));
      expect(
        contrastRatio(light.onSurfaceMuted, light.mint),
        greaterThan(_text),
      );
    });

    test('el rojo #B94343 no pasa sobre su fondo suave', () {
      const red = Color(0xFFB94343);
      expect(contrastRatio(red, light.alertFill), lessThan(_text));
      expect(contrastRatio(light.full, light.alertFill), greaterThan(_text));
    });

    test('el blanco sobre el teal del botón y sobre el petróleo pasa AA', () {
      expect(contrastRatio(white, light.primary), greaterThan(_text));
      expect(contrastRatio(white, light.brand), closeTo(12.08, 0.01));
    });
  });
}

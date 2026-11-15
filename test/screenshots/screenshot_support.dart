import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/pump_screen.dart';

/// Carga las fuentes reales de `fonts/` (y los íconos de Material del SDK) en
/// el motor de pruebas; sin esto las capturas saldrían con la fuente de
/// prueba (bloques).
Future<void> loadAppFonts() async {
  Future<void> load(String family, List<File> files) async {
    final loader = FontLoader(family);
    for (final file in files) {
      if (!file.existsSync()) continue;
      loader.addFont(
        Future.value(
          ByteData.sublistView(Uint8List.fromList(file.readAsBytesSync())),
        ),
      );
    }
    await loader.load();
  }

  await load('Inter', [
    File('fonts/Inter-Regular.ttf'),
    File('fonts/Inter-Medium.ttf'),
    File('fonts/Inter-SemiBold.ttf'),
    File('fonts/Inter-Bold.ttf'),
  ]);
  final root = Platform.environment['FLUTTER_ROOT'];
  if (root != null) {
    await load('MaterialIcons', [
      File(
        '$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ),
    ]);
  }
}

/// Un tamaño de pantalla de las capturas.
typedef ShotSize = ({int width, int height});

const ShotSize small = (width: 360, height: 800);
const ShotSize large = (width: 411, height: 891);

/// Alto de más para ver una pantalla entera sin desplazarla (360×1200).
const ShotSize tall = (width: 360, height: 1200);

/// Una variante de captura: tamaño, tema y escala de texto.
class Shot {
  const Shot(this.size, this.brightness, this.textScale, {this.keyboard = 0});

  final ShotSize size;
  final Brightness brightness;
  final double textScale;

  /// Alto del teclado abierto, en dp (0 = cerrado).
  final double keyboard;

  String get label {
    final theme = brightness == Brightness.dark ? 'dark' : 'light';
    final scale = textScale == 1 ? '1x' : '${textScale.toStringAsFixed(0)}x';
    final kb = keyboard > 0 ? '_keyboard' : '';
    return '${size.width}x${size.height}_${theme}_$scale$kb';
  }
}

/// Las capturas pedidas por pantalla: 360×800 en claro y oscuro a 1,0× y 2,0×,
/// y 411×891 solo en claro a 1,0×.
const List<Shot> standardShots = [
  Shot(small, Brightness.light, 1),
  Shot(small, Brightness.light, 2),
  Shot(small, Brightness.dark, 1),
  Shot(small, Brightness.dark, 2),
  Shot(large, Brightness.light, 1),
];

/// `/login` con el teclado abierto (claro y oscuro, 360×800 a 1,0×).
const List<Shot> keyboardShots = [
  Shot(small, Brightness.light, 1, keyboard: 280),
  Shot(small, Brightness.dark, 1, keyboard: 280),
];

/// Monta [screen] con la variante [shot] y guarda la captura en
/// `docs/screenshots/<name>_<variante>.png` (carpeta ignorada por git).
Future<void> takeShot(
  WidgetTester tester,
  String name,
  Shot shot,
  Widget screen, {
  Locale locale = const Locale('en'),
}) async {
  await pumpScreen(
    tester,
    screen,
    brightness: shot.brightness,
    textScale: shot.textScale,
    size: Size(shot.size.width.toDouble(), shot.size.height.toDouble()),
    keyboardHeight: shot.keyboard,
    pixelRatio: 2,
    locale: locale,
  );
  await tester.pumpAndSettle();
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('../../docs/screenshots/${name}_${shot.label}.png'),
  );
}

/// `flutter_test` apaga las sombras (salen como rectángulos duros): para las
/// capturas se encienden durante [body], porque la profundidad es parte del
/// diseño, y se restauran al terminar (si no, `flutter_test` detecta la
/// variable alterada y falla la prueba).
Future<void> withRealShadows(Future<void> Function() body) async {
  debugDisableShadows = false;
  try {
    await body();
  } finally {
    debugDisableShadows = true;
  }
}

@Tags(['screenshots'])
library;

// Capturas de Inicio y Ajustes con la app completa (shell, barra inferior y
// datos de prueba de assets/mocks/seed.json):
//   flutter test --tags screenshots --run-skipped --update-goldens
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/repositories/session_store.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/repositories/selected_lot_store.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

import '../contexts/iam/support.dart';
import '../helpers/app_harness.dart';
import 'screenshot_support.dart';

void main() {
  setUpAll(loadAppFonts);

  /// Monta la app con la sesión iniciada, con la variante [shot], y abre
  /// [path]. Sin latencia ni simulador: las capturas salen siempre igual.
  Future<void> shoot(
    WidgetTester tester,
    String name,
    Shot shot,
    String path, {
    int? selectedLot = 1,
    Future<void> Function(WidgetTester tester)? before,
  }) async {
    final size = Size(shot.size.width.toDouble(), shot.size.height.toDouble());
    const ratio = 2.0;
    FakeViewPadding insets({double top = 0, double bottom = 0}) =>
        FakeViewPadding(top: top * ratio, bottom: bottom * ratio);
    tester.view
      ..physicalSize = size * ratio
      ..devicePixelRatio = ratio
      ..padding = insets(top: 24, bottom: 24)
      ..viewPadding = insets(top: 24, bottom: 24);
    tester.platformDispatcher
      ..platformBrightnessTestValue = shot.brightness
      ..textScaleFactorTestValue = shot.textScale
      ..accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
        disableAnimations: true,
      );
    addTearDown(() {
      tester.view.reset();
      tester.platformDispatcher
        ..clearPlatformBrightnessTestValue()
        ..clearTextScaleFactorTestValue()
        ..clearAccessibilityFeaturesTestValue();
    });

    final harness = await AppHarness.create(
      seed: (locator) async {
        await locator<SessionStore>().save(sampleStored());
        if (selectedLot != null) {
          await locator<SelectedLotStore>().save(LotId(selectedLot));
        }
      },
    );
    addTearDown(harness.dispose);
    await tester.pumpWidget(harness.app());
    await tester.pumpAndSettle();
    harness.router.go(path);
    // Las cargas encadenadas (la sede, el ETA, la ocupación y la asesoría) se
    // resuelven entre cuadros: se les da tiempo antes de la captura.
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
    if (before != null) {
      await before(tester);
      await tester.pumpAndSettle();
    }

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../docs/screenshots/${name}_${shot.label}.png'),
    );
  }

  for (final shot in standardShots) {
    testWidgets('home ${shot.label}', (tester) async {
      await withRealShadows(() => shoot(tester, 'home', shot, '/home'));
    });
  }

  // Inicio entera, sin desplazar, en claro y oscuro a 1,0× y 2,0×.
  for (final shot in const [
    Shot(tall, Brightness.light, 1),
    Shot(tall, Brightness.light, 2),
    Shot(tall, Brightness.dark, 1),
    Shot(tall, Brightness.dark, 2),
  ]) {
    testWidgets('home ${shot.label}', (tester) async {
      await withRealShadows(() => shoot(tester, 'home', shot, '/home'));
    });
  }

  // Inicio en los demás estados de las sedes de prueba (docs/07): San Isidro
  // llena, Villa con el dato vencido, San Miguel sin distribución y sin sede
  // elegida.
  for (final (name, lot) in <(String, int?)>[
    ('home_full', 2),
    ('home_stale', 4),
    ('home_nodata', 3),
    ('home_prompt', null),
  ]) {
    for (final shot in [standardShots.first, standardShots[2]]) {
      testWidgets('$name ${shot.label}', (tester) async {
        await withRealShadows(
          () => shoot(tester, name, shot, '/home', selectedLot: lot),
        );
      });
    }
  }

  for (final (name, path) in [
    ('account', '/account'),
  ]) {
    for (final shot in standardShots) {
      testWidgets('$name ${shot.label}', (tester) async {
        await withRealShadows(() => shoot(tester, name, shot, path));
      });
    }
  }

  // Zonas: la sede, un pabellón con varios niveles, un nivel (mapa y lista) y
  // las sedes de prueba con otros estados.
  for (final (name, path, lot) in <(String, String, int)>[
    ('zones', '/zones', 1),
    ('zone', '/zones/11', 1),
    ('level', '/zones/11/levels/111', 1),
    ('zones_full', '/zones', 2),
    ('zones_stale', '/zones', 4),
    ('zones_nodata', '/zones', 3),
  ]) {
    for (final shot
        in name == 'zones' || name == 'zone' || name == 'level'
            ? standardShots
            : [standardShots.first, standardShots[2]]) {
      testWidgets('$name ${shot.label}', (tester) async {
        await withRealShadows(
          () => shoot(tester, name, shot, path, selectedLot: lot),
        );
      });
    }
  }
  for (final shot in [standardShots.first, standardShots[2]]) {
    testWidgets('level_list ${shot.label}', (tester) async {
      await withRealShadows(
        () => shoot(
          tester,
          'level_list',
          shot,
          '/zones/11/levels/111',
          before: (tester) async {
            await tester.tap(find.text('List'));
          },
        ),
      );
    });
  }

  // Predicción: la sede normal, con detalle, llena, con dato vencido y sin
  // distribución.
  for (final (name, lot) in <(String, int)>[
    ('forecast', 1),
    ('forecast_full', 2),
    ('forecast_nodata', 3),
  ]) {
    for (final shot
        in name == 'forecast'
            ? standardShots
            : [standardShots.first, standardShots[2]]) {
      testWidgets('$name ${shot.label}', (tester) async {
        await withRealShadows(
          () => shoot(tester, name, shot, '/forecast', selectedLot: lot),
        );
      });
    }
  }
  for (final shot in [standardShots.first, standardShots[2]]) {
    testWidgets('forecast_detail ${shot.label}', (tester) async {
      await withRealShadows(
        () => shoot(
          tester,
          'forecast_detail',
          shot,
          '/forecast',
          before: (tester) async {
            await tester.tap(find.text('30 min').first);
          },
        ),
      );
    });
  }

  // Alertas y preferencias, y la ventana de «Nueva franja».
  for (final shot in standardShots) {
    testWidgets('alerts ${shot.label}', (tester) async {
      await withRealShadows(() => shoot(tester, 'alerts', shot, '/alerts'));
    });
  }
  for (final shot in [standardShots.first, standardShots[2]]) {
    testWidgets('alerts_sheet ${shot.label}', (tester) async {
      await withRealShadows(
        () => shoot(
          tester,
          'alerts_sheet',
          shot,
          '/alerts',
          before: (tester) async {
            await tester.ensureVisible(find.text('Add a time slot'));
            await tester.tap(find.text('Add a time slot'));
          },
        ),
      );
    });
  }

  // «¿Cuándo llegas?»: el cálculo automático, el tráfico en tiempo real (con lo
  // que se comparte a la vista) y la hora a mano.
  for (final shot in [standardShots.first, standardShots[2]]) {
    testWidgets('eta_sheet ${shot.label}', (tester) async {
      await withRealShadows(
        () => shoot(
          tester,
          'eta_sheet',
          shot,
          '/home',
          before: (tester) async {
            await tester.tap(find.text('ARRIVE IN'));
          },
        ),
      );
    });
  }
}

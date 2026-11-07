// US01, US28: el resumen de términos y privacidad.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/contexts/iam/presentation/pages/legal_page.dart';

import '../../../helpers/pump_screen.dart';

void main() {
  Future<void> expectAccessible(WidgetTester tester) async {
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  }

  testWidgets('dice qué recibe y qué nunca recibe, y que no es el texto '
      'legal completo', (tester) async {
    await pumpScreen(tester, LegalPage(onBack: () {}));

    expect(find.text('Terms and privacy'), findsOneWidget);
    expect(find.text('What we receive'), findsOneWidget);
    expect(find.text('What we never receive'), findsOneWidget);
    expect(find.textContaining('Your location.'), findsOneWidget);
    expect(
      find.textContaining('only the minutes reach Quadrapp'),
      findsOneWidget,
    );
    // Con el tráfico activado, la ubicación aproximada va a Google: se dice.
    expect(find.textContaining('goes to Google'), findsOneWidget);
    expect(find.textContaining("Quadrapp doesn't receive it"), findsOneWidget);
    expect(find.text('When you sign out'), findsOneWidget);
    expect(
      find.textContaining("doesn't replace the full Terms and Privacy Policy"),
      findsOneWidget,
    );
  });

  testWidgets('la flecha de volver llama a onBack', (tester) async {
    var back = 0;
    await pumpScreen(tester, LegalPage(onBack: () => back++));

    await tester.tap(find.byTooltip('Back'));

    expect(back, 1);
  });

  for (final (scale, dark, locale) in [
    (1.0, false, const Locale('en')),
    (2.0, false, const Locale('en')),
    (1.0, true, const Locale('en')),
    (1.0, false, const Locale('es')),
  ]) {
    testWidgets(
      'accesible y sin desbordes (${scale}x${dark ? ', oscuro' : ''}, '
      '${locale.languageCode})',
      (tester) async {
        final handle = tester.ensureSemantics();
        await pumpScreen(
          tester,
          LegalPage(onBack: () {}),
          textScale: scale,
          brightness: dark ? Brightness.dark : Brightness.light,
          locale: locale,
        );

        expect(tester.takeException(), isNull);
        await expectAccessible(tester);
        handle.dispose();
      },
    );
  }

  testWidgets('en español', (tester) async {
    await pumpScreen(
      tester,
      LegalPage(onBack: () {}),
      locale: const Locale('es'),
    );

    expect(find.text('Términos y privacidad'), findsOneWidget);
    expect(find.text('Qué nunca recibimos'), findsOneWidget);
  });
}

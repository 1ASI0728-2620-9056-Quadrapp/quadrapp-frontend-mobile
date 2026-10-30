import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';

import '../../../helpers/pump_app.dart';

void main() {
  group('QaButton', () {
    testWidgets('muestra el texto y llama a onPressed', (tester) async {
      var taps = 0;
      await pumpInApp(
        tester,
        QaButton(label: 'Send code', onPressed: () => taps++),
      );

      await tester.tap(find.text('Send code'));

      expect(taps, 1);
    });

    testWidgets('deshabilitado no responde', (tester) async {
      await pumpInApp(
        tester,
        const QaButton(label: 'Send code', onPressed: null),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));

      expect(button.onPressed, isNull);
    });

    testWidgets('cargando bloquea el botón y expone la etiqueta accesible', (
      tester,
    ) async {
      var taps = 0;
      final handle = tester.ensureSemantics();
      await pumpInApp(
        tester,
        QaButton(
          label: 'Send code',
          loadingLabel: 'Loading',
          isLoading: true,
          onPressed: () => taps++,
        ),
      );

      await tester.tap(find.byType(FilledButton), warnIfMissed: false);

      expect(taps, 0);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('respeta el objetivo táctil mínimo de 48 dp', (tester) async {
      await pumpInApp(
        tester,
        QaButton(label: 'OK', onPressed: () {}, variant: QaButtonVariant.text),
      );

      final size = tester.getSize(find.byType(TextButton));

      expect(size.height, greaterThanOrEqualTo(48));
      expect(size.width, greaterThanOrEqualTo(48));
    });
  });

  group('QaOtpField', () {
    testWidgets('notifica cada cambio y avisa al completar el código', (
      tester,
    ) async {
      final changes = <String>[];
      String? completed;
      await pumpInApp(
        tester,
        QaOtpField(
          semanticLabel: 'Verification code',
          onChanged: changes.add,
          onCompleted: (code) => completed = code,
        ),
      );

      await tester.enterText(find.byType(TextField), '123');
      await tester.enterText(find.byType(TextField), '123456');

      expect(changes, ['123', '123456']);
      expect(completed, '123456');
    });

    testWidgets('acepta el código completo pegado y filtra lo que no es '
        'dígito', (tester) async {
      String? completed;
      await pumpInApp(
        tester,
        QaOtpField(
          semanticLabel: 'Verification code',
          onCompleted: (code) => completed = code,
        ),
      );

      await tester.enterText(find.byType(TextField), '12a 34-56');

      expect(completed, '123456');
    });

    testWidgets('recorta lo que sobra de 6 dígitos', (tester) async {
      String? last;
      await pumpInApp(
        tester,
        QaOtpField(
          semanticLabel: 'Verification code',
          onChanged: (v) => last = v,
        ),
      );

      await tester.enterText(find.byType(TextField), '12345678');

      expect(last, '123456');
    });

    testWidgets('declara AutofillHints.oneTimeCode', (tester) async {
      await pumpInApp(tester, const QaOtpField(semanticLabel: 'Code'));

      final field = tester.widget<TextField>(find.byType(TextField));

      expect(field.autofillHints, contains(AutofillHints.oneTimeCode));
    });

    testWidgets('pulsación larga pega el portapapeles', (tester) async {
      String? completed;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.getData') {
            return <String, dynamic>{'text': 'Your code: 654 321'};
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await pumpInApp(
        tester,
        QaOtpField(
          semanticLabel: 'Verification code',
          onCompleted: (code) => completed = code,
        ),
      );

      await tester.longPress(find.byType(QaOtpField));
      await tester.pump();

      expect(completed, '654321');
    });

    testWidgets('muestra el error con texto', (tester) async {
      await pumpInApp(
        tester,
        const QaOtpField(
          semanticLabel: 'Verification code',
          errorText: 'The code expired.',
        ),
      );

      expect(find.text('The code expired.'), findsOneWidget);
    });

    testWidgets('expone un único nodo semántico con la etiqueta', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpInApp(
        tester,
        const QaOtpField(semanticLabel: 'Verification code, 6 digits'),
      );

      expect(
        find.bySemanticsLabel('Verification code, 6 digits'),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('QaTextField', () {
    testWidgets('muestra etiqueta, ayuda y error', (tester) async {
      await pumpInApp(
        tester,
        const Column(
          children: [
            QaTextField(label: 'Email', helperText: 'We will email you.'),
            QaTextField(label: 'Other', errorText: 'Invalid email.'),
          ],
        ),
      );

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('We will email you.'), findsOneWidget);
      expect(find.text('Invalid email.'), findsOneWidget);
    });

    testWidgets('valida al salir del campo', (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await pumpInApp(
        tester,
        Column(
          children: [
            QaTextField(
              label: 'Email',
              focusNode: focus,
              validator: (v) =>
                  (v ?? '').contains('@') ? null : 'Invalid email.',
            ),
            const QaTextField(label: 'Next'),
          ],
        ),
      );

      await tester.enterText(find.byType(TextFormField).first, 'ana');
      await tester.pump();
      expect(find.text('Invalid email.'), findsNothing);

      await tester.tap(find.byType(TextFormField).last);
      await tester.pump();

      expect(find.text('Invalid email.'), findsOneWidget);
    });
  });

  group('QaTimeSlotPicker', () {
    Widget picker(
      Set<int> days,
      ValueChanged<Set<int>> onDays, {
      String? error,
      bool enabled = true,
    }) => QaTimeSlotPicker(
      dayLabels: const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
      dayNames: const [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ],
      selectedDays: days,
      from: const TimeOfDay(hour: 7, minute: 30),
      to: null,
      daysLabel: 'Days',
      fromLabel: 'From',
      toLabel: 'To',
      pickTimeLabel: 'Pick a time',
      onDaysChanged: onDays,
      onFromChanged: (_) {},
      onToChanged: (_) {},
      errorText: error,
      enabled: enabled,
    );

    testWidgets('agrega y quita días', (tester) async {
      Set<int>? result;
      await pumpInApp(tester, picker({1}, (days) => result = days));

      await tester.tap(find.text('Wed'));
      expect(result, {1, 3});

      await tester.tap(find.text('Mon'));
      expect(result, <int>{});
    });

    testWidgets('muestra la hora elegida, el aviso y el error', (tester) async {
      await pumpInApp(
        tester,
        picker({1}, (_) {}, error: 'The end time must be after the start.'),
      );

      expect(find.text('Pick a time'), findsOneWidget);
      expect(find.text('7:30 AM'), findsOneWidget);
      expect(
        find.text('The end time must be after the start.'),
        findsOneWidget,
      );
    });

    testWidgets('deshabilitado no cambia los días', (tester) async {
      Set<int>? result;
      await pumpInApp(
        tester,
        picker({1}, (days) => result = days, enabled: false),
      );

      await tester.tap(find.text('Wed'), warnIfMissed: false);

      expect(result, isNull);
    });
  });

  group('QaDialog', () {
    Future<bool?> open(WidgetTester tester, {bool destructive = false}) async {
      bool? result;
      await pumpInApp(
        tester,
        Builder(
          builder: (context) => QaButton(
            label: 'Open',
            onPressed: () async {
              result = await showQaDialog(
                context,
                title: 'Sign out',
                message: 'You will need a new code.',
                confirmLabel: 'Confirm',
                cancelLabel: 'Cancel',
                destructive: destructive,
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('confirmar devuelve true', (tester) async {
      await open(tester);

      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(find.text('Sign out'), findsNothing);
    });

    testWidgets('muestra título y mensaje', (tester) async {
      await open(tester);

      expect(find.text('Sign out'), findsOneWidget);
      expect(find.text('You will need a new code.'), findsOneWidget);
    });

    testWidgets('showQaDialog devuelve true al confirmar y false al cancelar', (
      tester,
    ) async {
      final results = <bool>[];
      await pumpInApp(
        tester,
        Builder(
          builder: (context) => QaButton(
            label: 'Open',
            onPressed: () async {
              results.add(
                await showQaDialog(
                  context,
                  title: 'T',
                  message: 'M',
                  confirmLabel: 'Confirm',
                  cancelLabel: 'Cancel',
                  destructive: true,
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(results, [true, false]);
    });
  });
}

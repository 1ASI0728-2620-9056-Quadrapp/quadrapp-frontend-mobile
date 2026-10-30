// US01, US03, TS01: /login y /login/verify en cada estado, con las guías de
// accesibilidad y el texto al 200 %.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quadrapp_mobile/contexts/iam/presentation/cubit/login_cubit.dart';
import 'package:quadrapp_mobile/contexts/iam/presentation/cubit/login_state.dart';
import 'package:quadrapp_mobile/contexts/iam/presentation/cubit/verify_code_cubit.dart';
import 'package:quadrapp_mobile/contexts/iam/presentation/cubit/verify_code_state.dart';
import 'package:quadrapp_mobile/contexts/iam/presentation/pages/login_page.dart';
import 'package:quadrapp_mobile/contexts/iam/presentation/pages/verify_code_page.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

import '../../../helpers/pump_app.dart';
import '../support.dart';

class _MockLoginCubit extends MockCubit<ViewState<LoginForm>>
    implements LoginCubit {}

class _MockVerifyCubit extends MockCubit<ViewState<VerifyForm>>
    implements VerifyCodeCubit {}

VerifyForm _form({
  Duration blocked = Duration.zero,
  bool resending = false,
  VerifyNotice? notice,
}) => VerifyForm(
  email: email(),
  resendBlockedFor: blocked,
  resending: resending,
  notice: notice,
);

/// Todas las guías de accesibilidad sobre lo que está en pantalla.
Future<void> _expectAccessible(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
}

void main() {
  group('LoginPage', () {
    late _MockLoginCubit cubit;

    setUp(() {
      cubit = _MockLoginCubit();
      when(() => cubit.submit(any())).thenAnswer((_) async {});
      when(() => cubit.emailChanged()).thenReturn(null);
      when(() => cubit.emailEditingFinished(any())).thenReturn(null);
    });

    Future<void> pumpLogin(
      WidgetTester tester,
      ViewState<LoginForm> state, {
      bool sessionExpired = false,
      VoidCallback? onNoticeShown,
      VoidCallback? onOpenLegal,
      double textScale = 1,
      Locale locale = const Locale('en'),
      Size size = const Size(400, 800),
    }) async {
      whenListen(
        cubit,
        const Stream<ViewState<LoginForm>>.empty(),
        initialState: state,
      );
      await pumpInApp(
        tester,
        BlocProvider<LoginCubit>.value(
          value: cubit,
          child: LoginPage(
            sessionExpired: sessionExpired,
            onNoticeShown: onNoticeShown,
            onOpenLegal: onOpenLegal,
          ),
        ),
        scrollable: false,
        textScale: textScale,
        locale: locale,
        size: size,
      );
      await tester.pump();
    }

    final states = <String, ViewState<LoginForm>>{
      'formulario': const ViewData(LoginForm()),
      'correo vacío': const ViewData(
        LoginForm(emailError: EmailFieldError.empty),
      ),
      'correo inválido': const ViewData(
        LoginForm(emailError: EmailFieldError.invalid),
      ),
      'enviando': const ViewLoading(),
      '403': const ViewError(ForbiddenFailure()),
      '400': const ViewError(ValidationFailure()),
      'sin red': const ViewError(NetworkFailure()),
      '5xx': const ViewError(ServerFailure()),
      '429': const ViewPartial(LoginForm(blockedFor: Duration(seconds: 45))),
    };

    for (final entry in states.entries) {
      testWidgets('${entry.key}: accesible y sin cortes al 200 %', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await pumpLogin(tester, entry.value);
        await _expectAccessible(tester);

        await pumpLogin(tester, entry.value, textScale: 2);
        expect(tester.takeException(), isNull);
        handle.dispose();
      });
    }

    testWidgets('formulario: título, campo y botón en inglés', (tester) async {
      await pumpLogin(tester, const ViewData(LoginForm()));

      expect(find.text('Plan your arrival at campus'), findsOneWidget);
      expect(find.text('Institutional email'), findsOneWidget);
      expect(find.text('name@university.edu'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Continue'), findsOneWidget);
      // La nota de privacidad: solo viajan los minutos, nunca la ubicación.
      expect(find.textContaining('Never your location'), findsOneWidget);
    });

    testWidgets('en español', (tester) async {
      await pumpLogin(
        tester,
        const ViewData(LoginForm()),
        locale: const Locale('es'),
      );

      expect(find.text('Anticipa tu llegada al campus'), findsOneWidget);
      expect(find.text('Correo institucional'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Continuar'), findsOneWidget);
      expect(find.textContaining('Nunca tu ubicación'), findsOneWidget);
    });

    testWidgets(
      'la línea legal es un solo botón de 48 dp que abre el resumen',
      (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        var opened = 0;
        await pumpLogin(
          tester,
          const ViewData(LoginForm()),
          onOpenLegal: () => opened++,
          size: const Size(400, 1000),
        );

        const line =
            'By continuing you accept the Terms and the Privacy Policy.';
        expect(find.bySemanticsLabel(line), findsOneWidget);
        expect(
          tester.getSemantics(find.bySemanticsLabel(line)),
          matchesSemantics(
            label: line,
            hint: 'Opens a summary of the terms and privacy',
            isButton: true,
            hasTapAction: true,
          ),
        );
        await tester.tap(find.bySemanticsLabel(line));
        expect(opened, 1);
        await _expectAccessible(tester);
        handle.dispose();
      },
    );

    testWidgets('sin destino, la línea legal es solo texto', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpLogin(
        tester,
        const ViewData(LoginForm()),
        size: const Size(400, 1000),
      );

      final line = find.textContaining('By continuing you accept');
      expect(line, findsOneWidget);
      expect(
        tester.getSemantics(line).getSemanticsData().flagsCollection.isButton,
        isFalse,
      );
      handle.dispose();
    });

    testWidgets('en español la línea legal conserva el orden del idioma', (
      tester,
    ) async {
      await pumpLogin(
        tester,
        const ViewData(LoginForm()),
        locale: const Locale('es'),
        onOpenLegal: () {},
      );

      expect(
        find.textContaining('Al continuar aceptas los Términos y la Política'),
        findsOneWidget,
      );
    });

    testWidgets('errores de formato con su texto', (tester) async {
      await pumpLogin(
        tester,
        const ViewData(LoginForm(emailError: EmailFieldError.invalid)),
      );

      expect(
        find.text('Enter a valid email, like name@university.edu.'),
        findsOneWidget,
      );
    });

    testWidgets('403: mensaje claro, sin reintento y con el foco en el aviso', (
      tester,
    ) async {
      await pumpLogin(tester, const ViewError(ForbiddenFailure()));
      await tester.pump();

      expect(
        find.text("That email doesn't belong to an enabled institution."),
        findsOneWidget,
      );
      expect(find.text('Try again'), findsNothing);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'QaBanner');
    });

    testWidgets('400: formato inválido según el servidor', (tester) async {
      await pumpLogin(tester, const ViewError(ValidationFailure()));

      expect(
        find.text("The email format isn't valid. Check it and try again."),
        findsOneWidget,
      );
    });

    testWidgets(
      'sin red: ofrece reintentar y reintenta con el correo escrito',
      (
        tester,
      ) async {
        await pumpLogin(tester, const ViewError(NetworkFailure()));
        await tester.enterText(
          find.byType(TextFormField),
          'conductor@upc.edu.pe',
        );

        await tester.tap(find.text('Try again'));
        await tester.pump();

        verify(() => cubit.submit('conductor@upc.edu.pe')).called(1);
      },
    );

    testWidgets('429: botón bloqueado con la cuenta regresiva m:ss', (
      tester,
    ) async {
      await pumpLogin(
        tester,
        const ViewPartial(LoginForm(blockedFor: Duration(seconds: 45))),
      );

      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNull);
      expect(find.text('Continue in 0:45'), findsOneWidget);
      expect(
        find.textContaining('Too many attempts'),
        findsOneWidget,
      );
    });

    testWidgets('enviando: el campo y el botón no se pueden usar', (
      tester,
    ) async {
      await pumpLogin(tester, const ViewLoading());

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.enabled, isFalse);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets(
      'al salir del campo valida; al escribir limpia; enviar pide el código',
      (
        tester,
      ) async {
        await pumpLogin(tester, const ViewData(LoginForm()));

        await tester.tap(find.byType(TextFormField));
        await tester.pump();
        await tester.enterText(find.byType(TextFormField), 'sin-arroba');
        verify(() => cubit.emailChanged()).called(greaterThan(0));

        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pump();
        verify(() => cubit.emailEditingFinished('sin-arroba')).called(1);

        await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
        verify(() => cubit.submit('sin-arroba')).called(1);
      },
    );

    testWidgets('sesión vencida: aviso claro y se avisa una sola vez', (
      tester,
    ) async {
      var shown = 0;
      await pumpLogin(
        tester,
        const ViewData(LoginForm()),
        sessionExpired: true,
        onNoticeShown: () => shown++,
      );
      await tester.pump();

      expect(
        find.text('Your session expired. Sign in again to continue.'),
        findsOneWidget,
      );
      expect(shown, 1);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'QaBanner');
    });
  });

  group('VerifyCodePage', () {
    late _MockVerifyCubit cubit;
    late int emailChanges;

    setUp(() {
      cubit = _MockVerifyCubit();
      emailChanges = 0;
      when(() => cubit.submit(any())).thenAnswer((_) async {});
      when(() => cubit.resend()).thenAnswer((_) async {});
      when(() => cubit.codeChanged()).thenReturn(null);
    });

    Future<void> pumpVerify(
      WidgetTester tester,
      ViewState<VerifyForm> state, {
      double textScale = 1,
      Locale locale = const Locale('en'),
    }) async {
      whenListen(
        cubit,
        const Stream<ViewState<VerifyForm>>.empty(),
        initialState: state,
      );
      await pumpInApp(
        tester,
        BlocProvider<VerifyCodeCubit>.value(
          value: cubit,
          child: VerifyCodePage(
            validity: const Duration(minutes: 5),
            onChangeEmail: () => emailChanges++,
          ),
        ),
        scrollable: false,
        textScale: textScale,
        locale: locale,
        size: const Size(400, 800),
      );
      await tester.pump();
    }

    final states = <String, ViewState<VerifyForm>>{
      'esperando reenvío': ViewData(
        _form(blocked: const Duration(seconds: 30)),
      ),
      'reenvío disponible': ViewData(_form()),
      'reenviando': ViewData(_form(resending: true)),
      'verificando': ViewLoading(previous: _form()),
      'código reenviado': ViewData(_form(notice: VerifyNotice.resent)),
      '401': ViewError(const UnauthorizedFailure(), previous: _form()),
      'sin red': ViewError(const NetworkFailure(), previous: _form()),
      'reenvío 429': ViewData(
        _form(
          blocked: const Duration(seconds: 45),
          notice: VerifyNotice.resendRateLimited,
        ),
      ),
    };

    for (final entry in states.entries) {
      testWidgets('${entry.key}: accesible y sin cortes al 200 %', (
        tester,
      ) async {
        final handle = tester.ensureSemantics();
        await pumpVerify(tester, entry.value);
        await _expectAccessible(tester);

        await pumpVerify(tester, entry.value, textScale: 2);
        expect(tester.takeException(), isNull);
        handle.dispose();
      });
    }

    testWidgets('muestra a qué correo se envió y la vigencia', (tester) async {
      await pumpVerify(tester, ViewData(_form()));

      // El correo va con la parte local oculta.
      expect(
        find.text('We sent a 6-digit code to c•••@upc.edu.pe.'),
        findsOneWidget,
      );
      expect(find.text('conductor@upc.edu.pe'), findsNothing);
      expect(find.text('The code is valid for 5 minutes.'), findsOneWidget);
      expect(find.text('Verification code'), findsOneWidget);
      // El aviso de que, si se corta la conexión, el código se conserva.
      expect(
        find.text(
          "If your connection drops, we'll keep your code so you can try "
          'again.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('permite corregir el correo', (tester) async {
      await pumpVerify(tester, ViewData(_form()));

      await tester.tap(find.byTooltip('Back'));

      expect(emailChanges, 1);
    });

    testWidgets('en español', (tester) async {
      await pumpVerify(
        tester,
        ViewData(_form()),
        locale: const Locale('es'),
      );

      expect(find.text('Verifica tu correo'), findsOneWidget);
      expect(find.text('Código de verificación'), findsOneWidget);
      expect(
        find.text('Enviamos un código de 6 dígitos a c•••@upc.edu.pe.'),
        findsOneWidget,
      );
      expect(find.text('Reenviar código'), findsOneWidget);
    });

    testWidgets('al completar los 6 dígitos verifica el código', (
      tester,
    ) async {
      await pumpVerify(tester, ViewData(_form()));

      await tester.enterText(find.byType(QaOtpField), '123456');
      await tester.pump();

      verify(() => cubit.submit('123456')).called(1);
    });

    testWidgets('el campo acepta el código completo pegado', (tester) async {
      await pumpVerify(tester, ViewData(_form()));

      await tester.enterText(find.byType(TextField), '123 456');
      await tester.pump();

      verify(() => cubit.submit('123456')).called(1);
    });

    testWidgets('el campo pide el autocompletado de código de un solo uso', (
      tester,
    ) async {
      await pumpVerify(tester, ViewData(_form()));

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.autofillHints, contains(AutofillHints.oneTimeCode));
    });

    testWidgets('401: "pide uno nuevo" con el foco en el aviso', (
      tester,
    ) async {
      await pumpVerify(
        tester,
        ViewError(const UnauthorizedFailure(), previous: _form()),
      );
      await tester.pump();

      expect(
        find.text("The code expired or doesn't match. Request a new one."),
        findsOneWidget,
      );
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'QaBanner');
    });

    testWidgets('sin red: ofrece reintentar', (tester) async {
      await pumpVerify(
        tester,
        ViewError(const NetworkFailure(), previous: _form()),
      );

      await tester.tap(find.text('Try again'));
      await tester.pump();

      verify(() => cubit.submit(any())).called(1);
    });

    testWidgets('verificando: no se puede escribir ni reenviar', (
      tester,
    ) async {
      await pumpVerify(tester, ViewLoading(previous: _form()));

      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      verifyNever(() => cubit.resend());
    });

    testWidgets('reenviar bloqueado: muestra la cuenta regresiva', (
      tester,
    ) async {
      await pumpVerify(
        tester,
        ViewData(_form(blocked: const Duration(seconds: 30))),
      );

      expect(find.text('Resend code in 0:30'), findsOneWidget);
      final resend = find.widgetWithText(TextButton, 'Resend code in 0:30');
      expect(tester.widget<TextButton>(resend).onPressed, isNull);
      verifyNever(() => cubit.resend());
    });

    testWidgets('reenviar disponible: pide un código nuevo', (tester) async {
      await pumpVerify(tester, ViewData(_form()));

      await tester.tap(find.text('Resend code'));

      verify(() => cubit.resend()).called(1);
    });

    testWidgets('código reenviado: aviso informativo', (tester) async {
      await pumpVerify(tester, ViewData(_form(notice: VerifyNotice.resent)));

      expect(find.text('We sent you a new code.'), findsOneWidget);
    });
  });
}

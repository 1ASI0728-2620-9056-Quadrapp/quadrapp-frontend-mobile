// US02, TS16: la cuenta (cierre de sesión confirmado) y las pestañas Zonas,
// Predicción y Alertas, en cada estado, con las guías de accesibilidad.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quadrapp_mobile/composition/settings/settings_page.dart';
import 'package:quadrapp_mobile/composition/sign_out/sign_out.dart';
import 'package:quadrapp_mobile/composition/sign_out/sign_out_cubit.dart';
import 'package:quadrapp_mobile/contexts/iam/iam.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/entities/device_token_removal.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

import '../../contexts/iam/support.dart';
import '../../helpers/pump_screen.dart';

class _MockSignOutCubit extends MockCubit<ViewState<SignOutReport>>
    implements SignOutCubit {}

const _email = 'conductor@upc.edu.pe';

Future<void> _expectAccessible(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
}

void main() {
  group('SettingsPage', () {
    late _MockSignOutCubit cubit;

    setUp(() {
      cubit = _MockSignOutCubit();
      when(() => cubit.signOut()).thenAnswer((_) async {});
    });

    Future<void> pumpPage(
      WidgetTester tester,
      ViewState<SignOutReport> state, {
      double textScale = 1,
      Brightness brightness = Brightness.light,
      Locale locale = const Locale('en'),
      UserRole role = UserRole.driver,
      Size size = const Size(360, 800),
    }) async {
      whenListen(
        cubit,
        const Stream<ViewState<SignOutReport>>.empty(),
        initialState: state,
      );
      await pumpScreen(
        tester,
        BlocProvider<SignOutCubit>.value(
          value: cubit,
          child: SettingsPage(session: sampleSession(role: role), tabIndex: 3),
        ),
        textScale: textScale,
        brightness: brightness,
        locale: locale,
        size: size,
      );
      await tester.pump();
    }

    final states = <String, ViewState<SignOutReport>>{
      'inicial': const ViewInitial(),
      'cerrando': const ViewLoading(),
      'error': const ViewError(UnknownFailure()),
      'cerrada': const ViewData(
        SignOutReport(
          pushToken: DeviceTokenRemoval.nothingToRemove,
          sessionRevoked: true,
        ),
      ),
    };

    for (final entry in states.entries) {
      for (final (scale, dark) in [(1.0, false), (2.0, false), (1.0, true)]) {
        testWidgets(
          '${entry.key}: accesible, sin desbordes '
          '(${scale}x${dark ? ', oscuro' : ''})',
          (tester) async {
            final handle = tester.ensureSemantics();
            await pumpPage(
              tester,
              entry.value,
              textScale: scale,
              brightness: dark ? Brightness.dark : Brightness.light,
            );

            expect(tester.takeException(), isNull);
            await _expectAccessible(tester);
            handle.dispose();
          },
        );
      }
    }

    testWidgets('la tarjeta de cuenta muestra correo, institución y rol', (
      tester,
    ) async {
      await pumpPage(tester, const ViewInitial());

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text(_email), findsOneWidget);
      expect(find.text('Universidad de prueba'), findsOneWidget);
      expect(find.text('Role'), findsOneWidget);
      expect(find.text('Driver'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
    });

    testWidgets('el rol se muestra para cualquier rol, con la misma pantalla', (
      tester,
    ) async {
      for (final (role, label) in [
        (UserRole.driver, 'Driver'),
        (UserRole.operator, 'Operator'),
        (UserRole.admin, 'Administrator'),
      ]) {
        await pumpPage(tester, const ViewInitial(), role: role);

        expect(find.text(label), findsOneWidget);
        expect(find.widgetWithText(FilledButton, 'Sign out'), findsOneWidget);
      }
    });

    testWidgets('en español', (tester) async {
      await pumpPage(
        tester,
        const ViewInitial(),
        locale: const Locale('es'),
        role: UserRole.admin,
      );

      expect(find.text('Ajustes'), findsOneWidget);
      expect(find.text('Rol'), findsOneWidget);
      expect(find.text('Administrador'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Cerrar sesión'),
        findsOneWidget,
      );
    });

    testWidgets('la tarjeta se anuncia como un solo bloque', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpPage(tester, const ViewInitial());

      expect(
        find.bySemanticsLabel(
          'Account: $_email, Universidad de prueba, role Driver',
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('pide confirmación nombrando la cuenta; cancelar no cierra', (
      tester,
    ) async {
      await pumpPage(tester, const ViewInitial());

      await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
      await tester.pumpAndSettle();
      expect(find.text('Sign out?'), findsOneWidget);
      expect(
        find.text(
          "You'll sign out of $_email on this device and will need a code "
          'to sign in again.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      verifyNever(() => cubit.signOut());
    });

    testWidgets('confirmar cierra la sesión', (tester) async {
      await pumpPage(tester, const ViewInitial());

      await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Sign out').last);
      await tester.pumpAndSettle();

      verify(() => cubit.signOut()).called(1);
    });

    testWidgets('error: aviso con el foco y salida (volver a intentar)', (
      tester,
    ) async {
      await pumpPage(tester, const ViewError(UnknownFailure()));
      await tester.pump();

      expect(find.text("We couldn't sign you out. Try again."), findsOneWidget);
      expect(FocusManager.instance.primaryFocus?.debugLabel, 'QaBanner');
      expect(find.widgetWithText(FilledButton, 'Sign out'), findsOneWidget);
    });

    testWidgets('cerrando: el botón muestra progreso y se bloquea', (
      tester,
    ) async {
      await pumpPage(tester, const ViewLoading());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Signing out…'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
    });
  });

  group('la cuenta del Conductor (una pantalla con volver)', () {
    testWidgets('lleva la flecha de volver y el título Account, sin pestaña', (
      tester,
    ) async {
      var back = 0;
      final cubit = _MockSignOutCubit();
      whenListen(
        cubit,
        const Stream<ViewState<SignOutReport>>.empty(),
        initialState: const ViewInitial<SignOutReport>(),
      );
      await pumpScreen(
        tester,
        BlocProvider<SignOutCubit>.value(
          value: cubit,
          child: SettingsPage(session: sampleSession(), onBack: () => back++),
        ),
      );

      expect(find.text('Account'), findsOneWidget);
      expect(find.text(_email), findsOneWidget);
      await tester.tap(find.byTooltip('Back'));
      expect(back, 1);
    });

    testWidgets('es una pestaña o una pantalla con volver, no ambas', (
      tester,
    ) async {
      expect(
        () => SettingsPage(
          session: sampleSession(),
          tabIndex: 3,
          onBack: () {},
        ),
        throwsAssertionError,
      );
      expect(
        () => SettingsPage(session: sampleSession()),
        throwsAssertionError,
      );
    });
  });
}

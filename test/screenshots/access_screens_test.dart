@Tags(['screenshots'])
library;

// Capturas de /login y /login/verify para revisar el diseño:
//   flutter test --tags screenshots --run-skipped --update-goldens
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/contexts/iam/presentation/cubit/login_cubit.dart';
import 'package:quadrapp_mobile/contexts/iam/presentation/cubit/login_state.dart';
import 'package:quadrapp_mobile/contexts/iam/presentation/cubit/verify_code_cubit.dart';
import 'package:quadrapp_mobile/contexts/iam/presentation/cubit/verify_code_state.dart';
import 'package:quadrapp_mobile/contexts/iam/presentation/pages/login_page.dart';
import 'package:quadrapp_mobile/contexts/iam/presentation/pages/verify_code_page.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

import '../contexts/iam/support.dart';
import 'screenshot_support.dart';

class _MockLoginCubit extends MockCubit<ViewState<LoginForm>>
    implements LoginCubit {}

class _MockVerifyCubit extends MockCubit<ViewState<VerifyForm>>
    implements VerifyCodeCubit {}

void main() {
  setUpAll(loadAppFonts);

  Widget login() {
    final cubit = _MockLoginCubit();
    whenListen(
      cubit,
      const Stream<ViewState<LoginForm>>.empty(),
      initialState: const ViewData(LoginForm()),
    );
    return BlocProvider<LoginCubit>.value(
      value: cubit,
      child: const LoginPage(),
    );
  }

  Widget verify() {
    final cubit = _MockVerifyCubit();
    whenListen(
      cubit,
      const Stream<ViewState<VerifyForm>>.empty(),
      initialState: ViewData(
        VerifyForm(
          email: email(),
          resendBlockedFor: const Duration(seconds: 30),
        ),
      ),
    );
    return BlocProvider<VerifyCodeCubit>.value(
      value: cubit,
      child: VerifyCodePage(
        validity: const Duration(minutes: 5),
        onChangeEmail: () {},
      ),
    );
  }

  for (final shot in [...standardShots, ...keyboardShots]) {
    testWidgets('login ${shot.label}', (tester) async {
      await withRealShadows(
        () => takeShot(tester, 'login', shot, login()),
      );
    });
  }

  for (final shot in standardShots) {
    testWidgets('verify ${shot.label}', (tester) async {
      await withRealShadows(
        () => takeShot(tester, 'verify', shot, verify()),
      );
    });
  }
}

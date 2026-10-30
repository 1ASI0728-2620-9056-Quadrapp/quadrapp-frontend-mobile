// US01, US02, US03, TS01: cubits de iam.
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quadrapp_mobile/contexts/iam/application/usecases/request_otp.dart';
import 'package:quadrapp_mobile/contexts/iam/application/usecases/restore_session.dart';
import 'package:quadrapp_mobile/contexts/iam/application/usecases/sign_in_with_otp.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/entities/otp_challenge.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/entities/session.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/user_role.dart';
import 'package:quadrapp_mobile/contexts/iam/presentation/cubit/auth_cubit.dart';
import 'package:quadrapp_mobile/contexts/iam/presentation/cubit/login_cubit.dart';
import 'package:quadrapp_mobile/contexts/iam/presentation/cubit/login_state.dart';
import 'package:quadrapp_mobile/contexts/iam/presentation/cubit/verify_code_cubit.dart';
import 'package:quadrapp_mobile/contexts/iam/presentation/cubit/verify_code_state.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/time/countdown.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

import '../../../helpers/fake_clock.dart';
import '../support.dart';

class _MockRestoreSession extends Mock implements RestoreSession {}

class _MockRequestOtp extends Mock implements RequestOtp {}

class _MockSignInWithOtp extends Mock implements SignInWithOtp {}

class _FakeSignInParams extends Fake implements SignInWithOtpParams {}

const _mail = 'conductor@upc.edu.pe';
const _code = '123456';

/// Un reloj y un ticker que se mueven solo cuando la prueba lo ordena.
class _Time {
  final FakeClock clock = FakeClock();
  final StreamController<void> ticks = StreamController<void>.broadcast();

  late final Countdown countdown = Countdown(clock, ticker: () => ticks.stream);

  /// Avanza el tiempo y deja que la cuenta regresiva lo note.
  Future<void> pass(Duration duration) async {
    clock.advance(duration);
    ticks.add(null);
    await pumpEventQueue();
  }

  Future<void> dispose() => ticks.close();
}

OtpChallenge _challenge(
  FakeClock clock, {
  Duration validity = const Duration(minutes: 5),
}) => OtpChallenge(
  email: email(),
  expiresIn: validity,
  receivedAt: clock.monotonic(),
);

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeSignInParams());
    registerFallbackValue(const NoParams());
    registerFallbackValue('');
  });

  group('AuthCubit', () {
    late _MockRestoreSession restore;

    setUp(() => restore = _MockRestoreSession());

    blocTest<AuthCubit, AuthState>(
      'restaura la sesión guardada sin pedir un código (US01 esc. 6)',
      build: () {
        when(() => restore(any())).thenAnswer(
          (_) async => Success<Session?>(sampleSession(role: UserRole.admin)),
        );
        return AuthCubit(restoreSession: restore);
      },
      act: (cubit) => cubit.restore(),
      expect: () => [
        isA<Authenticated>().having(
          (state) => state.session,
          'session',
          sampleSession(role: UserRole.admin),
        ),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'sin sesión guardada, o si no se puede leer: sin sesión',
      build: () {
        var calls = 0;
        when(() => restore(any())).thenAnswer((_) async {
          calls++;
          return calls == 1
              ? const Success<Session?>(null)
              : const Err<Session?>(UnknownFailure());
        });
        return AuthCubit(restoreSession: restore);
      },
      act: (cubit) async {
        await cubit.restore();
        await cubit.restore();
      },
      // El segundo `Unauthenticated` es igual al primero: no se repite.
      expect: () => [const Unauthenticated()],
    );

    blocTest<AuthCubit, AuthState>(
      'inicio y fin de sesión cambian el estado',
      build: () => AuthCubit(restoreSession: restore),
      act: (cubit) => cubit
        ..sessionStarted(sampleSession())
        ..sessionEnded(),
      expect: () => [
        Authenticated(sampleSession()),
        const Unauthenticated(),
      ],
    );
  });

  group('LoginCubit', () {
    late _MockRequestOtp requestOtp;
    late _Time time;
    late List<OtpChallenge> sent;

    setUp(() {
      requestOtp = _MockRequestOtp();
      time = _Time();
      sent = [];
    });

    tearDown(() => time.dispose());

    LoginCubit build() => LoginCubit(
      requestOtp: requestOtp,
      countdown: time.countdown,
      onCodeSent: sent.add,
    );

    void serverReturns(Result<OtpChallenge> result) =>
        when(() => requestOtp(any())).thenAnswer((_) async => result);

    blocTest<LoginCubit, ViewState<LoginForm>>(
      'al salir del campo valida el formato (vacío e inválido)',
      build: build,
      act: (cubit) => cubit
        ..emailEditingFinished('  ')
        ..emailEditingFinished('sin-arroba')
        ..emailEditingFinished(_mail),
      expect: () => [
        const ViewData(LoginForm(emailError: EmailFieldError.empty)),
        const ViewData(LoginForm(emailError: EmailFieldError.invalid)),
        const ViewData(LoginForm()),
      ],
    );

    blocTest<LoginCubit, ViewState<LoginForm>>(
      'un correo inválido no llega al servidor (400 local)',
      build: build,
      act: (cubit) => cubit.submit('sin-arroba'),
      expect: () => [
        const ViewData(LoginForm(emailError: EmailFieldError.invalid)),
      ],
      verify: (_) => verifyNever(() => requestOtp(any())),
    );

    blocTest<LoginCubit, ViewState<LoginForm>>(
      'código enviado: avisa con el desafío y vuelve al formulario',
      build: () {
        serverReturns(Success(_challenge(time.clock)));
        return build();
      },
      act: (cubit) => cubit.submit(_mail),
      expect: () => [
        const ViewLoading<LoginForm>(),
        const ViewData(LoginForm()),
      ],
      verify: (_) {
        expect(sent, hasLength(1));
        expect(sent.single.email, email());
      },
    );

    blocTest<LoginCubit, ViewState<LoginForm>>(
      '403: correo sin institución; al escribir se puede reintentar',
      build: () {
        serverReturns(const Err(ForbiddenFailure()));
        return build();
      },
      act: (cubit) async {
        await cubit.submit(_mail);
        cubit.emailChanged();
      },
      expect: () => [
        const ViewLoading<LoginForm>(),
        const ViewError<LoginForm>(ForbiddenFailure()),
        const ViewData(LoginForm()),
      ],
      verify: (_) => expect(sent, isEmpty),
    );

    blocTest<LoginCubit, ViewState<LoginForm>>(
      'red caída: error recuperable y el reintento vuelve a pedir el código',
      build: () {
        serverReturns(const Err(NetworkFailure()));
        return build();
      },
      act: (cubit) async {
        await cubit.submit(_mail);
        await cubit.submit(_mail);
      },
      expect: () => [
        const ViewLoading<LoginForm>(),
        const ViewError<LoginForm>(NetworkFailure()),
        const ViewLoading<LoginForm>(),
        const ViewError<LoginForm>(NetworkFailure()),
      ],
      verify: (_) => verify(() => requestOtp(_mail)).called(2),
    );

    blocTest<LoginCubit, ViewState<LoginForm>>(
      '429: cuenta regresiva desde retryAfter, bloqueado hasta cero',
      build: () {
        serverReturns(
          const Err(RateLimitedFailure(retryAfter: Duration(seconds: 45))),
        );
        return build();
      },
      act: (cubit) async {
        await cubit.submit(_mail);
        await pumpEventQueue();
        // Bloqueado: pedir otra vez no llama al servidor.
        await cubit.submit(_mail);
        await time.pass(const Duration(seconds: 1));
        await time.pass(const Duration(seconds: 44));
      },
      expect: () => [
        const ViewLoading<LoginForm>(),
        const ViewPartial(LoginForm(blockedFor: Duration(seconds: 45))),
        const ViewPartial(LoginForm(blockedFor: Duration(seconds: 44))),
        const ViewData(LoginForm()),
      ],
      verify: (_) => verify(() => requestOtp(_mail)).called(1),
    );

    test('un 429 sin retryAfter usa la espera por defecto', () async {
      serverReturns(const Err(RateLimitedFailure()));
      final cubit = build();
      addTearDown(cubit.close);

      await cubit.submit(_mail);
      await pumpEventQueue();

      expect(
        cubit.state,
        const ViewPartial(LoginForm(blockedFor: LoginCubit.defaultRetryAfter)),
      );
    });
  });

  group('VerifyCodeCubit', () {
    late _MockSignInWithOtp signIn;
    late _MockRequestOtp requestOtp;
    late _Time time;
    late List<Session> signedIn;

    setUp(() {
      signIn = _MockSignInWithOtp();
      requestOtp = _MockRequestOtp();
      time = _Time();
      signedIn = [];
    });

    tearDown(() => time.dispose());

    VerifyCodeCubit build({OtpChallenge? challenge}) => VerifyCodeCubit(
      challenge: challenge ?? _challenge(time.clock),
      signIn: signIn,
      requestOtp: requestOtp,
      clock: time.clock,
      countdown: time.countdown,
      onSignedIn: signedIn.add,
    );

    VerifyForm form({
      Duration blocked = VerifyCodeCubit.resendCooldown,
      bool resending = false,
      VerifyNotice? notice,
    }) => VerifyForm(
      email: email(),
      resendBlockedFor: blocked,
      resending: resending,
      notice: notice,
    );

    void signInReturns(Result<Session> result) =>
        when(() => signIn(any())).thenAnswer((_) async => result);

    blocTest<VerifyCodeCubit, ViewState<VerifyForm>>(
      'código válido: inicia la sesión con el rol que el servidor devuelve',
      build: () {
        signInReturns(Success(sampleSession(role: UserRole.operator)));
        return build();
      },
      act: (cubit) => cubit.submit(_code),
      expect: () => [
        ViewLoading(previous: form()),
        ViewData(form()),
      ],
      verify: (_) {
        expect(signedIn.single, sampleSession(role: UserRole.operator));
        verify(
          () => signIn(
            const SignInWithOtpParams(email: _mail, code: _code),
          ),
        ).called(1);
      },
    );

    blocTest<VerifyCodeCubit, ViewState<VerifyForm>>(
      '401: incorrecto o vencido; al escribir se limpia el error',
      build: () {
        signInReturns(const Err(UnauthorizedFailure()));
        return build();
      },
      act: (cubit) async {
        await cubit.submit(_code);
        cubit.codeChanged();
      },
      expect: () => [
        ViewLoading(previous: form()),
        ViewError(const UnauthorizedFailure(), previous: form()),
        ViewData(form()),
      ],
      verify: (_) => expect(signedIn, isEmpty),
    );

    blocTest<VerifyCodeCubit, ViewState<VerifyForm>>(
      'sin red: error recuperable; reintentar vuelve a verificar',
      build: () {
        signInReturns(const Err(NetworkFailure()));
        return build();
      },
      act: (cubit) async {
        await cubit.submit(_code);
        await cubit.submit(_code);
      },
      expect: () => [
        ViewLoading(previous: form()),
        ViewError(const NetworkFailure(), previous: form()),
        ViewLoading(previous: form()),
        ViewError(const NetworkFailure(), previous: form()),
      ],
      verify: (_) => verify(() => signIn(any())).called(2),
    );

    blocTest<VerifyCodeCubit, ViewState<VerifyForm>>(
      'con la vigencia vencida no llama al servidor: pide uno nuevo',
      build: () {
        final cubit = build(
          challenge: _challenge(
            time.clock,
            validity: const Duration(minutes: 1),
          ),
        );
        time.clock.advance(const Duration(minutes: 2));
        return cubit;
      },
      act: (cubit) => cubit.submit(_code),
      expect: () => [
        ViewError(const UnauthorizedFailure(), previous: form()),
      ],
      verify: (_) => verifyNever(() => signIn(any())),
    );

    blocTest<VerifyCodeCubit, ViewState<VerifyForm>>(
      'reenviar: bloqueado durante la cuenta regresiva y luego disponible',
      build: () {
        when(() => requestOtp(any())).thenAnswer(
          (_) async => Success(_challenge(time.clock)),
        );
        return build();
      },
      act: (cubit) async {
        await pumpEventQueue();
        // Todavía en cuenta regresiva: no hace nada.
        await cubit.resend();
        await time.pass(const Duration(seconds: 10));
        await time.pass(const Duration(seconds: 20));
        await cubit.resend();
      },
      expect: () => [
        ViewData(form(blocked: const Duration(seconds: 20))),
        ViewData(form(blocked: Duration.zero)),
        ViewData(form(blocked: Duration.zero, resending: true)),
        ViewData(form(notice: VerifyNotice.resent)),
      ],
      verify: (_) => verify(() => requestOtp(_mail)).called(1),
    );

    blocTest<VerifyCodeCubit, ViewState<VerifyForm>>(
      'reenviar con 429: espera el retryAfter del servidor',
      build: () {
        when(() => requestOtp(any())).thenAnswer(
          (_) async =>
              const Err(RateLimitedFailure(retryAfter: Duration(seconds: 45))),
        );
        return build();
      },
      act: (cubit) async {
        await pumpEventQueue();
        await time.pass(const Duration(seconds: 30));
        await cubit.resend();
        await pumpEventQueue();
      },
      expect: () => [
        ViewData(form(blocked: Duration.zero)),
        ViewData(form(blocked: Duration.zero, resending: true)),
        ViewData(
          form(
            blocked: const Duration(seconds: 45),
            notice: VerifyNotice.resendRateLimited,
          ),
        ),
      ],
    );

    test('reenviar sin red deja un aviso y no bloquea', () async {
      when(
        () => requestOtp(any()),
      ).thenAnswer((_) async => const Err(NetworkFailure()));
      final cubit = build();
      addTearDown(cubit.close);
      await pumpEventQueue();
      await time.pass(const Duration(seconds: 30));

      await cubit.resend();

      expect(
        cubit.state,
        ViewData(
          form(blocked: Duration.zero, notice: VerifyNotice.resendNetworkError),
        ),
      );
    });
  });

  group('privacidad', () {
    test(
      'ningún estado muestra el correo ni el código al imprimirse',
      () async {
        final time = _Time();
        addTearDown(time.dispose);
        final signIn = _MockSignInWithOtp();
        when(
          () => signIn(any()),
        ).thenAnswer((_) async => const Err(UnauthorizedFailure()));
        final cubit = VerifyCodeCubit(
          challenge: _challenge(time.clock),
          signIn: signIn,
          requestOtp: _MockRequestOtp(),
          clock: time.clock,
          countdown: time.countdown,
          onSignedIn: (_) {},
        );
        addTearDown(cubit.close);
        final seen = <String>[cubit.state.toString()];
        cubit.stream.listen((state) => seen.add(state.toString()));

        await cubit.submit(_code);
        await pumpEventQueue();

        expect(seen.length, greaterThan(1));
        for (final text in seen) {
          expect(text, isNot(contains(_mail)));
          expect(text, isNot(contains(_code)));
        }
      },
    );
  });
}

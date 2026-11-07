import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quadrapp_mobile/contexts/iam/application/usecases/expire_session.dart';
import 'package:quadrapp_mobile/contexts/iam/application/usecases/refresh_session.dart';
import 'package:quadrapp_mobile/contexts/iam/application/usecases/request_otp.dart';
import 'package:quadrapp_mobile/contexts/iam/application/usecases/restore_session.dart';
import 'package:quadrapp_mobile/contexts/iam/application/usecases/sign_in_with_otp.dart';
import 'package:quadrapp_mobile/contexts/iam/application/usecases/sign_out_usecases.dart';
import 'package:quadrapp_mobile/contexts/iam/application/usecases/watch_session_expiry.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/entities/otp_challenge.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/repositories/auth_repository.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/email_address.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/otp_code.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/refresh_token.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/user_role.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/mappers/iam_mapper.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/repositories/in_memory_access_token_holder.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/repositories/session_store_impl.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/repositories/stream_session_events.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/storage/key_value_store.dart';
import 'package:quadrapp_mobile/core/storage/secure_store.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

import '../../helpers/recording_logger.dart';
import 'support.dart';

class _MockAuth extends Mock implements AuthRepository {}

class _FakeEmail extends Fake implements EmailAddress {}

class _FakeCode extends Fake implements OtpCode {}

class _FakeRefreshToken extends Fake implements RefreshToken {}

/// Un almacén seguro que falla al escribir.
class _FailingSecureStore extends InMemorySecureStore {
  @override
  Future<void> write(String key, String value) =>
      throw StateError('keystore no disponible');
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeEmail());
    registerFallbackValue(_FakeCode());
    registerFallbackValue(_FakeRefreshToken());
  });

  late _MockAuth auth;
  late InMemoryKeyValueStore values;
  late InMemorySecureStore secrets;
  late SessionStoreImpl sessions;
  late InMemoryAccessTokenHolder accessHolder;
  late StreamSessionEvents events;

  SessionStoreImpl buildStore(SecureStore secure) => SessionStoreImpl(
    values: values,
    secrets: secure,
    mapper: IamMapper(RecordingLogger()),
  );

  setUp(() {
    auth = _MockAuth();
    values = InMemoryKeyValueStore();
    secrets = InMemorySecureStore();
    sessions = buildStore(secrets);
    accessHolder = InMemoryAccessTokenHolder();
    events = StreamSessionEvents();
  });

  tearDown(() => events.dispose());

  ExpireSession expire() => ExpireSession(
    sessions: sessions,
    accessToken: accessHolder,
    events: events,
  );

  RefreshSession refresh() => RefreshSession(
    auth: auth,
    sessions: sessions,
    accessToken: accessHolder,
    expire: expire(),
  );

  Future<void> givenStoredSession() => sessions.save(sampleStored());

  group('RequestOtp (US01 esc. 1, 5; TS01 esc. 2)', () {
    OtpChallenge challenge() => OtpChallenge(
      email: email(),
      expiresIn: const Duration(minutes: 5),
      receivedAt: Duration.zero,
    );

    test('pide el código y devuelve su vigencia', () async {
      when(
        () => auth.requestOtp(any()),
      ).thenAnswer((_) async => Success(challenge()));

      final result = await RequestOtp(auth)('  Conductor@UPC.edu.pe ');

      expect(result.valueOrNull?.expiresIn, const Duration(minutes: 5));
      // El correo se normaliza antes de llegar al servidor.
      verify(() => auth.requestOtp(email())).called(1);
    });

    test('un correo con formato inválido no llega al servidor', () async {
      final result = await RequestOtp(auth)('no-es-un-correo');

      expect(result.failureOrNull, isA<ValidationFailure>());
      verifyNever(() => auth.requestOtp(any()));
    });

    test('403: el correo no es de una institución habilitada', () async {
      when(
        () => auth.requestOtp(any()),
      ).thenAnswer((_) async => const Err(ForbiddenFailure()));

      final result = await RequestOtp(auth)('alguien@otra.com');

      expect(result.failureOrNull, isA<ForbiddenFailure>());
    });

    test('429: trae el retryAfter para la cuenta regresiva', () async {
      when(() => auth.requestOtp(any())).thenAnswer(
        (_) async => const Err(
          RateLimitedFailure(retryAfter: Duration(seconds: 45)),
        ),
      );

      final result = await RequestOtp(auth)('conductor@upc.edu.pe');

      expect(
        (result.failureOrNull! as RateLimitedFailure).retryAfter,
        const Duration(seconds: 45),
      );
    });
  });

  group('SignInWithOtp (US01 esc. 2 y 3)', () {
    SignInWithOtp signIn({SessionStoreImpl? store}) => SignInWithOtp(
      auth: auth,
      sessions: store ?? sessions,
      accessToken: accessHolder,
    );

    const params = SignInWithOtpParams(
      email: 'conductor@upc.edu.pe',
      code: '123456',
    );

    test('con un código válido guarda la sesión y el refresh token', () async {
      when(
        () => auth.login(any(), any()),
      ).thenAnswer((_) async => Success(sampleGrant()));

      final result = await signIn()(params);

      expect(result.valueOrNull, sampleSession());
      expect((await sessions.read())?.refreshToken, refreshToken());
      expect(accessHolder.current, accessToken());
    });

    test(
      'el access token solo en memoria; el refresh solo en el almacén seguro',
      () async {
        when(
          () => auth.login(any(), any()),
        ).thenAnswer((_) async => Success(sampleGrant()));

        await signIn()(params);

        final userJson = await values.getString('user.session');
        expect(userJson, isNot(contains('access-1')));
        expect(userJson, isNot(contains('refresh-1')));
        expect(await secrets.read('refreshToken'), 'refresh-1');
        expect(await secrets.read('accessToken'), isNull);
      },
    );

    test('se acepta cualquier rol y se guarda', () async {
      for (final role in UserRole.values) {
        when(
          () => auth.login(any(), any()),
        ).thenAnswer((_) async => Success(sampleGrant(role: role)));

        final result = await signIn()(params);

        expect(result.valueOrNull?.role, role);
        expect((await sessions.read())?.session.role, role);
      }
    });

    test('401: código incorrecto o vencido, no se guarda nada', () async {
      when(
        () => auth.login(any(), any()),
      ).thenAnswer((_) async => const Err(UnauthorizedFailure()));

      final result = await signIn()(params);

      expect(result.failureOrNull, isA<UnauthorizedFailure>());
      expect(await sessions.read(), isNull);
      expect(accessHolder.current, isNull);
    });

    test('un código que no son 6 dígitos no llega al servidor', () async {
      final result = await signIn()(
        const SignInWithOtpParams(email: 'conductor@upc.edu.pe', code: '12'),
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
      verifyNever(() => auth.login(any(), any()));
    });

    test(
      'si no se guarda la sesión, falla y no deja un access token suelto',
      () async {
        when(
          () => auth.login(any(), any()),
        ).thenAnswer((_) async => Success(sampleGrant()));

        final result = await signIn(store: buildStore(_FailingSecureStore()))(
          params,
        );

        expect(result.isFailure, isTrue);
        expect(accessHolder.current, isNull);
      },
    );

    test('los parámetros no muestran el correo ni el código al imprimirse', () {
      expect('$params', isNot(contains('123456')));
      expect('$params', isNot(contains('conductor')));
    });
  });

  group('RestoreSession (US01 esc. 6)', () {
    test('sin sesión guardada devuelve null', () async {
      final result = await RestoreSession(sessions)(const NoParams());

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isNull);
    });

    test('con sesión guardada la devuelve sin llamar al servidor', () async {
      await givenStoredSession();

      final result = await RestoreSession(sessions)(const NoParams());

      expect(result.valueOrNull, sampleSession());
      verifyZeroInteractions(auth);
      // El access token no se restaura: solo vive en memoria.
      expect(accessHolder.current, isNull);
    });
  });

  group('RefreshSession (TS01 esc. 5 y 6, US03)', () {
    test('renueva el access token y conserva la sesión', () async {
      await givenStoredSession();
      when(
        () => auth.refresh(any()),
      ).thenAnswer((_) async => Success(accessToken('access-2')));

      final result = await refresh()(const NoParams());

      expect(result.valueOrNull, accessToken('access-2'));
      expect(accessHolder.current, accessToken('access-2'));
      expect(await sessions.read(), isNotNull);
    });

    test('varias llamadas a la vez comparten un solo refresh', () async {
      await givenStoredSession();
      final gate = Completer<void>();
      when(() => auth.refresh(any())).thenAnswer((_) async {
        await gate.future;
        return Success(accessToken('access-2'));
      });
      final useCase = refresh();

      final calls = Future.wait([
        for (var i = 0; i < 5; i++) useCase(const NoParams()),
      ]);
      await Future<void>.delayed(Duration.zero);
      gate.complete();
      final results = await calls;

      expect(
        results.every((r) => r.valueOrNull == accessToken('access-2')),
        isTrue,
      );
      verify(() => auth.refresh(refreshToken())).called(1);
    });

    test(
      'un solo intento por ronda: una ronda nueva hace una llamada nueva',
      () async {
        await givenStoredSession();
        when(
          () => auth.refresh(any()),
        ).thenAnswer((_) async => const Err(NetworkFailure()));
        final useCase = refresh();

        await useCase(const NoParams());
        await useCase(const NoParams());

        // No reintenta por su cuenta: una llamada por ronda.
        verify(() => auth.refresh(any())).called(2);
      },
    );

    test('401: la sesión expiró; se limpia y se avisa una vez', () async {
      await givenStoredSession();
      accessHolder.replace(accessToken());
      when(
        () => auth.refresh(any()),
      ).thenAnswer((_) async => const Err(UnauthorizedFailure()));
      final expired = <Object>[];
      final subscription = events.expired.listen(expired.add);

      final result = await refresh()(const NoParams());
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(result.failureOrNull, isA<UnauthorizedFailure>());
      expect(await sessions.read(), isNull);
      expect(accessHolder.current, isNull);
      expect(expired, hasLength(1));
    });

    test('sin red NO expira la sesión', () async {
      await givenStoredSession();
      when(
        () => auth.refresh(any()),
      ).thenAnswer((_) async => const Err(NetworkFailure()));
      var expired = 0;
      final subscription = events.expired.listen((_) => expired++);

      final result = await refresh()(const NoParams());
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(result.failureOrNull, isA<NetworkFailure>());
      expect(await sessions.read(), isNotNull);
      expect(expired, 0);
    });

    test('sin refresh token guardado no llama al servidor', () async {
      final result = await refresh()(const NoParams());

      expect(result.failureOrNull, isA<UnauthorizedFailure>());
      verifyNever(() => auth.refresh(any()));
    });
  });

  group('ExpireSession y WatchSessionExpiry (US03)', () {
    test(
      'limpia la sesión y emite un aviso; repetirlo no emite otro',
      () async {
        await givenStoredSession();
        accessHolder.replace(accessToken());
        final watched = <Object>[];
        final sub = WatchSessionExpiry(events)().listen(watched.add);

        await expire()(const NoParams());
        await expire()(const NoParams());
        await Future<void>.delayed(Duration.zero);
        await sub.cancel();

        expect(watched, hasLength(1));
        expect(await sessions.read(), isNull);
        expect(accessHolder.current, isNull);
      },
    );
  });

  group('RevokeSession y ClearSession (US02)', () {
    test('revoca el refresh token guardado en el servidor', () async {
      await givenStoredSession();
      when(
        () => auth.logout(any()),
      ).thenAnswer((_) async => const Success<void>(null));

      final result = await RevokeSession(
        auth: auth,
        sessions: sessions,
      )(const NoParams());

      expect(result.isSuccess, isTrue);
      verify(() => auth.logout(refreshToken())).called(1);
    });

    test('un 401 cuenta como éxito: la sesión ya no era válida', () async {
      await givenStoredSession();
      when(
        () => auth.logout(any()),
      ).thenAnswer((_) async => const Err(UnauthorizedFailure()));

      final result = await RevokeSession(
        auth: auth,
        sessions: sessions,
      )(const NoParams());

      expect(result.isSuccess, isTrue);
    });

    test(
      'sin red devuelve la falla (mejor esfuerzo, no bloquea el cierre)',
      () async {
        await givenStoredSession();
        when(
          () => auth.logout(any()),
        ).thenAnswer((_) async => const Err(NetworkFailure()));

        final result = await RevokeSession(
          auth: auth,
          sessions: sessions,
        )(const NoParams());

        expect(result.failureOrNull, isA<NetworkFailure>());
      },
    );

    test('sin refresh token no hay nada que revocar', () async {
      final result = await RevokeSession(
        auth: auth,
        sessions: sessions,
      )(const NoParams());

      expect(result.isSuccess, isTrue);
      verifyNever(() => auth.logout(any()));
    });

    test(
      'ClearSession borra el usuario, el refresh token y el access token',
      () async {
        await givenStoredSession();
        accessHolder.replace(accessToken());

        await ClearSession(
          sessions: sessions,
          accessToken: accessHolder,
        )(const NoParams());

        expect(await sessions.read(), isNull);
        expect(await secrets.read('refreshToken'), isNull);
        expect(await values.getString('user.session'), isNull);
        expect(accessHolder.current, isNull);
      },
    );
  });
}

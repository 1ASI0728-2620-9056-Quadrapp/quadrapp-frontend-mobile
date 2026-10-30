import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/otp_code.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/user_role.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/datasources/auth_http_datasource.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/dto/auth_dtos.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/mappers/iam_mapper.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/repositories/auth_repository_impl.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/repositories/session_store_impl.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/storage/key_value_store.dart';
import 'package:quadrapp_mobile/core/storage/secure_store.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/fake_http_adapter.dart';
import '../../helpers/recording_logger.dart';
import 'support.dart';

const Object _absent = Object();

void main() {
  late RecordingLogger logger;
  late IamMapper mapper;

  setUp(() {
    logger = RecordingLogger();
    mapper = IamMapper(logger);
  });

  AuthRepositoryImpl repositoryOn(
    FakeHttpAdapter adapter, {
    FakeClock? clock,
  }) => AuthRepositoryImpl(
    remote: AuthHttpDataSource(dioWith(adapter)),
    mapper: mapper,
    clock: clock ?? FakeClock(),
  );

  OtpCode code() => OtpCode.create('123456').valueOrNull!;

  group('IamMapper', () {
    test('caso feliz: sesión con rol e institución', () {
      final grant = mapper.toGrant(LoginResponseDto.fromJson(loginJson()));

      expect(grant.session, sampleSession());
      expect(grant.accessToken, accessToken());
      expect(grant.refreshToken, refreshToken());
      expect(logger.messages, isEmpty);
    });

    test('un rol desconocido se trata como DRIVER y deja un aviso', () {
      final session = mapper.toSession(
        UserDto.fromJson(
          loginJson(role: 'SUPERUSER')['user']! as Map<String, dynamic>,
        ),
      );

      expect(session.role, UserRole.driver);
      expect(logger.messages, hasLength(1));
      expect(logger.messages.single, isNot(contains('conductor@')));
    });

    test('el nombre completo es opcional; vacío o ausente es "sin nombre" y '
        'nunca se deriva del correo', () {
      Map<String, dynamic> user([Object? fullName = _absent]) => {
        ...loginJson()['user']! as Map<String, dynamic>,
        if (fullName != _absent) 'fullName': fullName,
      };

      expect(
        mapper.toSession(UserDto.fromJson(user('  Camila Rojas '))).fullName,
        'Camila Rojas',
      );
      expect(mapper.toSession(UserDto.fromJson(user())).fullName, isNull);
      expect(mapper.toSession(UserDto.fromJson(user(null))).fullName, isNull);
      expect(mapper.toSession(UserDto.fromJson(user('   '))).fullName, isNull);
    });

    test('los roles se leen sin distinguir mayúsculas', () {
      expect(mapper.parseRole('operator'), UserRole.operator);
      expect(mapper.parseRole('ADMIN'), UserRole.admin);
      expect(logger.messages, isEmpty);
    });
  });

  group('AuthRepositoryImpl', () {
    test(
      'POST /auth/otp: devuelve la vigencia con el reloj monótono',
      () async {
        final clock = FakeClock()..advance(const Duration(seconds: 7));
        final adapter = FakeHttpAdapter(
          (_) => jsonResponse({'expiresInSec': 300}, status: 202),
        );

        final result = await repositoryOn(
          adapter,
          clock: clock,
        ).requestOtp(email());

        final challenge = result.valueOrNull!;
        expect(challenge.expiresIn, const Duration(seconds: 300));
        expect(challenge.receivedAt, const Duration(seconds: 7));
        expect(adapter.requests.single.data, {'email': 'conductor@upc.edu.pe'});
      },
    );

    test('POST /auth/login envía solo email y code', () async {
      final adapter = FakeHttpAdapter((_) => jsonResponse(loginJson()));

      final result = await repositoryOn(adapter).login(email(), code());

      expect(result.valueOrNull?.session, sampleSession());
      expect(adapter.requests.single.data, {
        'email': 'conductor@upc.edu.pe',
        'code': '123456',
      });
    });

    test('403, 429 con retryAfterSec y 401 llegan como sus Failure', () async {
      Future<Failure?> failureFor(
        int status, [
        Map<String, Object?>? body,
      ]) async {
        final adapter = FakeHttpAdapter(
          (_) => jsonResponse(body ?? {'title': 'x'}, status: status),
        );
        return (await repositoryOn(adapter).requestOtp(email())).failureOrNull;
      }

      expect(await failureFor(403), isA<ForbiddenFailure>());
      expect(await failureFor(401), isA<UnauthorizedFailure>());
      final limited = await failureFor(429, {'retryAfterSec': 45});
      expect(
        (limited! as RateLimitedFailure).retryAfter,
        const Duration(seconds: 45),
      );
    });

    test('un error de red es NetworkFailure', () async {
      final adapter = FakeHttpAdapter(
        (options) => throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        ),
      );

      final result = await repositoryOn(adapter).login(email(), code());

      expect(result.failureOrNull, isA<NetworkFailure>());
    });

    test('una respuesta ilegible es ParseFailure', () async {
      final notAnObject = FakeHttpAdapter((_) => jsonResponse([1]));
      final emptyToken = FakeHttpAdapter(
        (_) => jsonResponse(loginJson(accessToken: '')),
      );
      final badEmail = FakeHttpAdapter(
        (_) => jsonResponse(loginJson(userEmail: 'no-correo')),
      );

      for (final adapter in [notAnObject, emptyToken, badEmail]) {
        final result = await repositoryOn(adapter).login(email(), code());
        expect(result.failureOrNull, isA<ParseFailure>());
      }
    });

    test('refresh y logout envían el refresh token en el cuerpo', () async {
      final adapter = FakeHttpAdapter((options) {
        return options.path == '/auth/refresh'
            ? jsonResponse({'accessToken': 'access-2'})
            : emptyResponse(204);
      });
      final repository = repositoryOn(adapter);

      final refreshed = await repository.refresh(refreshToken());
      final loggedOut = await repository.logout(refreshToken());

      expect(refreshed.valueOrNull, accessToken('access-2'));
      expect(loggedOut.isSuccess, isTrue);
      expect(adapter.requests.map((r) => r.data), [
        {'refreshToken': 'refresh-1'},
        {'refreshToken': 'refresh-1'},
      ]);
    });
  });

  group('SessionStoreImpl', () {
    late InMemoryKeyValueStore values;
    late InMemorySecureStore secrets;
    late SessionStoreImpl store;

    setUp(() {
      values = InMemoryKeyValueStore();
      secrets = InMemorySecureStore();
      store = SessionStoreImpl(
        values: values,
        secrets: secrets,
        mapper: mapper,
      );
    });

    test('guarda el refresh token solo en el almacén seguro', () async {
      await store.save(sampleStored(role: UserRole.operator));

      expect(await secrets.read('refreshToken'), 'refresh-1');
      final json = await values.getString('user.session');
      expect(json, isNot(contains('refresh-1')));
      expect(json, contains('OPERATOR'));
      expect((await store.read())?.session.role, UserRole.operator);
    });

    test('lo guardado dañado cuenta como sin sesión y se limpia', () async {
      await values.setString('user.session', '{no es json');
      await secrets.write('refreshToken', 'refresh-1');

      expect(await store.read(), isNull);
      expect(await secrets.read('refreshToken'), isNull);
      expect(await values.getString('user.session'), isNull);
    });

    test('reset() borra todo; el borrado por prefijo user. también', () async {
      await store.save(sampleStored());
      await store.reset();
      expect(await store.read(), isNull);

      await store.save(sampleStored());
      await values.removeByPrefix(StoreKeys.user);
      // Sin el usuario guardado ya no hay sesión (aunque quede el token).
      expect(await store.read(), isNull);
    });
  });
}

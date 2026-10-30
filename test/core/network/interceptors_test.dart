import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/core/logging/logger.dart';
import 'package:quadrapp_mobile/core/network/api_language.dart';
import 'package:quadrapp_mobile/core/network/auth_interceptor.dart';
import 'package:quadrapp_mobile/core/network/locale_interceptor.dart';
import 'package:quadrapp_mobile/core/network/safe_log_interceptor.dart';

import '../../helpers/fake_http_adapter.dart';

class _RecordingLogger implements Logger {
  final List<String> lines = [];

  @override
  void warning(String message, {Object? error}) => lines.add(message);
}

class _FakeTokens implements AuthTokenSource {
  _FakeTokens(this.accessToken);

  @override
  String? accessToken;

  int refreshCalls = 0;

  /// El token que entrega el refresh; `null` = el servidor lo rechaza.
  String? nextToken;

  /// `true` = el refresh no se pudo intentar (sin red).
  bool unavailable = false;
  Completer<void>? gate;

  @override
  Future<TokenRefresh> refreshAccessToken() async {
    refreshCalls++;
    await gate?.future;
    if (unavailable) return const Unavailable();
    final token = nextToken;
    if (token == null) return const Rejected();
    accessToken = token;
    return Refreshed(token);
  }
}

void main() {
  test('apiLanguageTag mapea en -> en-US y es -> es-419', () {
    expect(apiLanguageTag('en'), 'en-US');
    expect(apiLanguageTag('es'), 'es-419');
    expect(apiLanguageTag('fr'), 'en-US');
  });

  test('LocaleInterceptor envía Accept-Language', () async {
    final adapter = FakeHttpAdapter((_) => jsonResponse({}));
    final dio = dioWith(adapter, interceptors: [LocaleInterceptor(() => 'es')]);

    await dio.get<dynamic>('/x');

    expect(adapter.requests.single.headers['Accept-Language'], 'es-419');
  });

  group('SafeLogInterceptor', () {
    test('solo escribe método, ruta, estado y duración; nunca cabeceras ni '
        'cuerpos', () async {
      final logger = _RecordingLogger();
      final adapter = FakeHttpAdapter(
        (_) => jsonResponse({'accessToken': 'SECRET'}),
      );
      final dio = dioWith(adapter, interceptors: [SafeLogInterceptor(logger)]);

      await dio.post<dynamic>(
        '/auth/login',
        data: {'email': 'a@upc.edu.pe', 'code': '123456'},
        options: Options(headers: {'Authorization': 'Bearer SECRET'}),
      );

      final log = logger.lines.join('\n');
      expect(log, contains('POST /api/v1/auth/login → 200'));
      for (final secret in ['SECRET', '123456', 'a@upc.edu.pe', 'Bearer']) {
        expect(log, isNot(contains(secret)));
      }
    });

    test('oculta el token push en la ruta y descarta la query', () {
      expect(
        SafeLogInterceptor.redactPath('/api/v1/device-tokens/abc:DEF-123?x=1'),
        '/api/v1/device-tokens/<redactado>',
      );
      expect(
        SafeLogInterceptor.redactPath('/api/v1/forecasts?lotId=1&horizon=15'),
        '/api/v1/forecasts',
      );
    });

    test('también registra los errores, sin datos sensibles', () async {
      final logger = _RecordingLogger();
      final adapter = FakeHttpAdapter(
        (_) => jsonResponse({'detail': 'algo con SECRET'}, status: 500),
      );
      final dio = dioWith(adapter, interceptors: [SafeLogInterceptor(logger)]);

      await expectLater(dio.get<dynamic>('/x'), throwsA(isA<DioException>()));

      expect(logger.lines.single, contains('GET /api/v1/x → 500'));
      expect(logger.lines.single, isNot(contains('SECRET')));
    });
  });

  group('AuthInterceptor', () {
    Dio build(
      FakeHttpAdapter adapter,
      _FakeTokens tokens, {
      void Function()? onExpired,
    }) {
      final dio = dioWith(adapter);
      dio.interceptors.add(
        AuthInterceptor(
          dio: dio,
          tokens: tokens,
          onSessionExpired: onExpired ?? () {},
        ),
      );
      return dio;
    }

    test('agrega Authorization, salvo en las rutas públicas', () async {
      final adapter = FakeHttpAdapter((_) => jsonResponse({}));
      final dio = build(adapter, _FakeTokens('T1'));

      await dio.get<dynamic>('/parking-lots');
      await dio.post<dynamic>('/auth/otp');

      expect(adapter.requests[0].headers['Authorization'], 'Bearer T1');
      expect(adapter.requests[1].headers.containsKey('Authorization'), isFalse);
    });

    test('ante un 401 hace un solo refresh compartido y reintenta cada '
        'petición', () async {
      final tokens = _FakeTokens('OLD')
        ..nextToken = 'NEW'
        ..gate = Completer<void>();
      final adapter = FakeHttpAdapter((options) {
        return options.headers['Authorization'] == 'Bearer NEW'
            ? jsonResponse({'ok': true})
            : jsonResponse({'title': 'expired'}, status: 401);
      });
      final dio = build(adapter, tokens);

      final calls = Future.wait([
        dio.get<dynamic>('/a'),
        dio.get<dynamic>('/b'),
        dio.get<dynamic>('/c'),
      ]);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      tokens.gate!.complete();
      final responses = await calls;

      expect(tokens.refreshCalls, 1);
      expect(responses.map((r) => r.statusCode), [200, 200, 200]);
      // 3 intentos con el token viejo + 3 reintentos con el nuevo.
      expect(adapter.requests, hasLength(6));
    });

    test('si el servidor rechaza el refresh, avisa que la sesión expiró y deja '
        'pasar el 401', () async {
      final tokens = _FakeTokens('OLD');
      var expired = 0;
      final adapter = FakeHttpAdapter(
        (_) => jsonResponse({'title': 'expired'}, status: 401),
      );
      final dio = build(adapter, tokens, onExpired: () => expired++);

      await expectLater(
        dio.get<dynamic>('/a'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'status',
            401,
          ),
        ),
      );

      expect(tokens.refreshCalls, 1);
      expect(expired, 1);
    });

    test(
      'si el refresh no se pudo hacer (sin red), la sesión NO expira',
      () async {
        final tokens = _FakeTokens('OLD')..unavailable = true;
        var expired = 0;
        final adapter = FakeHttpAdapter(
          (_) => jsonResponse({'title': 'expired'}, status: 401),
        );
        final dio = build(adapter, tokens, onExpired: () => expired++);

        await expectLater(dio.get<dynamic>('/a'), throwsA(isA<DioException>()));

        expect(tokens.refreshCalls, 1);
        expect(expired, 0);
      },
    );

    test(
      'la baja del token push es pública: sin Authorization y sin refresh',
      () async {
        final tokens = _FakeTokens('T1')..nextToken = 'NEW';
        final adapter = FakeHttpAdapter(
          (_) => jsonResponse({'title': 'nope'}, status: 401),
        );
        final dio = build(adapter, tokens);

        await expectLater(
          dio.post<dynamic>('/device-tokens/unregister', data: {'token': 'x'}),
          throwsA(isA<DioException>()),
        );

        expect(
          adapter.requests.single.headers.containsKey('Authorization'),
          isFalse,
        );
        expect(tokens.refreshCalls, 0);
      },
    );

    test(
      'no entra en bucle: un 401 en el reintento se devuelve tal cual',
      () async {
        final tokens = _FakeTokens('OLD')..nextToken = 'NEW';
        final adapter = FakeHttpAdapter(
          (_) => jsonResponse({'title': 'nope'}, status: 401),
        );
        final dio = build(adapter, tokens);

        await expectLater(dio.get<dynamic>('/a'), throwsA(isA<DioException>()));

        expect(tokens.refreshCalls, 1);
        expect(adapter.requests, hasLength(2));
      },
    );

    test('un 401 en una ruta pública no dispara refresh', () async {
      final tokens = _FakeTokens('OLD')..nextToken = 'NEW';
      final adapter = FakeHttpAdapter(
        (_) => jsonResponse({'title': 'bad code'}, status: 401),
      );
      final dio = build(adapter, tokens);

      await expectLater(
        dio.post<dynamic>('/auth/login'),
        throwsA(isA<DioException>()),
      );

      expect(tokens.refreshCalls, 0);
    });
  });
}

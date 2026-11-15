import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/network/failure_mapper.dart';
import 'package:quadrapp_mobile/core/network/parse_exception.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

DioException _response(
  int status, {
  Object? data,
  Map<String, List<String>> headers = const {},
}) {
  final options = RequestOptions(path: '/x');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: options,
      statusCode: status,
      data: data,
      headers: Headers.fromMap(headers),
    ),
  );
}

DioException _type(DioExceptionType type) => DioException(
  requestOptions: RequestOptions(path: '/x'),
  type: type,
);

void main() {
  group('failureFromDio', () {
    test('errores de transporte son NetworkFailure', () {
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.connectionError,
      ]) {
        expect(failureFromDio(_type(type)), const NetworkFailure());
      }
    });

    test('401, 403 y 404', () {
      expect(failureFromDio(_response(401)), isA<UnauthorizedFailure>());
      expect(failureFromDio(_response(403)), isA<ForbiddenFailure>());
      expect(failureFromDio(_response(404)), isA<NotFoundFailure>());
    });

    test('400, 409 y 422 son ValidationFailure con los errores por campo', () {
      final failure = failureFromDio(
        _response(
          400,
          data: {
            'type': 'about:blank',
            'title': 'Bad Request',
            'status': 400,
            'detail': 'ETA inválido',
            'errors': {
              'etaMinutes': ['debe ser menor o igual a 120'],
            },
          },
        ),
      );

      expect(
        failure,
        const ValidationFailure('ETA inválido', {
          'etaMinutes': ['debe ser menor o igual a 120'],
        }),
      );
      expect(failureFromDio(_response(409)), isA<ValidationFailure>());
      expect(failureFromDio(_response(422)), isA<ValidationFailure>());
    });

    test('429 lee retryAfterSec del cuerpo', () {
      final failure = failureFromDio(
        _response(429, data: {'retryAfterSec': 45}),
      );

      expect(failure, isA<RateLimitedFailure>());
      expect(
        (failure as RateLimitedFailure).retryAfter,
        const Duration(seconds: 45),
      );
    });

    test('429 usa Retry-After si el cuerpo no lo trae', () {
      final failure = failureFromDio(
        _response(
          429,
          headers: {
            'retry-after': ['30'],
          },
        ),
      );

      expect(
        (failure as RateLimitedFailure).retryAfter,
        const Duration(seconds: 30),
      );
    });

    test('5xx es ServerFailure con el código', () {
      expect(
        failureFromDio(_response(503, data: {'title': 'Down'})),
        const ServerFailure('Down', 503),
      );
    });

    test('una respuesta de error que no es JSON no rompe el mapeo', () {
      expect(
        failureFromDio(_response(500, data: '<html>')),
        isA<ServerFailure>(),
      );
    });
  });

  group('failureFromError', () {
    test('un JSON que no coincide es ParseFailure', () {
      expect(failureFromError(const ParseException('x')), isA<ParseFailure>());
      expect(failureFromError(const FormatException('x')), isA<ParseFailure>());
      expect(failureFromError(TypeError()), isA<ParseFailure>());
    });

    test('cualquier otra cosa es UnknownFailure', () {
      expect(failureFromError(StateError('x')), isA<UnknownFailure>());
    });
  });

  group('guardResult', () {
    test('éxito', () async {
      expect(await guardResult(() async => 3), const Success(3));
    });

    test('convierte las excepciones en Err, sin propagarlas', () async {
      final result = await guardResult<int>(
        () async => throw _response(401),
      );

      expect(result.failureOrNull, isA<UnauthorizedFailure>());
    });
  });
}

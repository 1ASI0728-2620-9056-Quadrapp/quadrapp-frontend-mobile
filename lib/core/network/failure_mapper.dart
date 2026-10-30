import 'dart:io';

import 'package:dio/dio.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/network/parse_exception.dart';
import 'package:quadrapp_mobile/core/network/problem_details.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// Traduce una excepción de `dio` a una [Failure]. Es el único traductor: lo
/// usan todos los repositorios (vía [guardResult]).
Failure failureFromDio(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
    case DioExceptionType.connectionError:
      return const NetworkFailure();
    case DioExceptionType.badResponse:
      return _failureFromResponse(error.response);
    case DioExceptionType.badCertificate:
    case DioExceptionType.cancel:
      return const UnknownFailure();
    case DioExceptionType.unknown:
      final inner = error.error;
      if (inner is SocketException || inner is HttpException) {
        return const NetworkFailure();
      }
      if (inner != null && inner is! DioException) {
        return failureFromError(inner);
      }
      return const UnknownFailure();
  }
}

Failure _failureFromResponse(Response<dynamic>? response) {
  final status = response?.statusCode ?? 0;
  final problem = ProblemDetails.tryParse(response?.data);
  final message = problem?.detail ?? problem?.title;
  return switch (status) {
    400 ||
    409 ||
    422 => ValidationFailure(message, problem?.errors ?? const {}),
    401 => UnauthorizedFailure(message),
    403 => ForbiddenFailure(message),
    404 => NotFoundFailure(message),
    429 => RateLimitedFailure(
      retryAfter: _retryAfter(response, problem),
      message: message,
    ),
    >= 500 => ServerFailure(message, status),
    _ => UnknownFailure(message),
  };
}

Duration? _retryAfter(Response<dynamic>? response, ProblemDetails? problem) {
  final seconds =
      problem?.retryAfterSec ??
      int.tryParse(response?.headers.value('retry-after') ?? '');
  return seconds == null ? null : Duration(seconds: seconds);
}

/// Traduce cualquier error inesperado a una [Failure]. Un JSON que no coincide
/// con el contrato es un [ParseFailure].
Failure failureFromError(Object error) {
  return switch (error) {
    DioException() => failureFromDio(error),
    ParseException(:final message) => ParseFailure(message),
    CheckedFromJsonException(:final message) => ParseFailure(message),
    TypeError() || FormatException() => ParseFailure(error.toString()),
    SocketException() => const NetworkFailure(),
    _ => UnknownFailure(error.toString()),
  };
}

/// Ejecuta [action] y devuelve un [Result]: las excepciones de infraestructura
/// se convierten en [Failure] aquí, y no cruzan a application ni a
/// presentation.
Future<Result<T>> guardResult<T>(Future<T> Function() action) async {
  try {
    return Success(await action());
  } on Object catch (error) {
    return Err(failureFromError(error));
  }
}

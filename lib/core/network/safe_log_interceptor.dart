import 'package:dio/dio.dart';
import 'package:quadrapp_mobile/core/logging/logger.dart';

/// Registro de peticiones para debug. Solo escribe método, ruta, estado y
/// duración: nunca cabeceras ni cuerpos, así que no puede filtrar contraseñas,
/// códigos OTP, tokens ni `Authorization`. Además, los segmentos de la ruta que
/// son un token (`/device-tokens/{token}`) se ocultan.
///
/// Se registra solo en debug (`app/di`); en release no existe.
class SafeLogInterceptor extends Interceptor {
  SafeLogInterceptor(this._logger, {Stopwatch Function()? stopwatch})
    : _stopwatch = stopwatch ?? Stopwatch.new;

  final Logger _logger;
  final Stopwatch Function() _stopwatch;

  static const _watchKey = 'quadrapp.log.watch';

  /// Rutas cuyo último segmento es un secreto.
  static final RegExp _secretSegment = RegExp('(/device-tokens/)[^/?#]+');

  /// Oculta lo sensible de una ruta y descarta la query string.
  static String redactPath(String path) {
    final withoutQuery = path.split('?').first;
    return withoutQuery.replaceAllMapped(
      _secretSegment,
      (match) => '${match.group(1)}<redactado>',
    );
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_watchKey] = _stopwatch()..start();
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    _log(response.requestOptions, response.statusCode);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log(err.requestOptions, err.response?.statusCode, type: err.type.name);
    handler.next(err);
  }

  void _log(RequestOptions options, int? status, {String? type}) {
    final watch = options.extra[_watchKey];
    final ms = watch is Stopwatch ? watch.elapsedMilliseconds : null;
    _logger.warning(
      '${options.method} ${redactPath(options.uri.path)} → '
      '${status ?? type ?? '?'}${ms == null ? '' : ' (${ms}ms)'}',
    );
  }
}

import 'package:dio/dio.dart';
import 'package:quadrapp_mobile/core/network/api_language.dart';

/// Envía `Accept-Language` en cada petición (TS16).
class LocaleInterceptor extends Interceptor {
  /// `languageCode` devuelve el idioma actual de la app (`en` o `es`).
  LocaleInterceptor(this._languageCode);

  final String Function() _languageCode;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Accept-Language'] = apiLanguageTag(_languageCode());
    handler.next(options);
  }
}

// Los campos privados no pueden ser parámetros con nombre público.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import 'package:dio/dio.dart';

/// Origen del token de acceso. Lo implementa `iam` (infraestructura); `core`
/// solo conoce esta interfaz.
abstract interface class AuthTokenSource {
  /// El token de acceso actual (en memoria), o `null` si no hay sesión.
  String? get accessToken;

  /// Pide un nuevo token de acceso con el refresh token. Distingue "el
  /// servidor lo rechazó" (la sesión expiró) de "no se pudo intentar" (sin red,
  /// 5xx): solo lo primero cierra la sesión.
  Future<TokenRefresh> refreshAccessToken();
}

/// Resultado de renovar el token de acceso.
sealed class TokenRefresh {
  const TokenRefresh();
}

/// Hay un token de acceso nuevo.
final class Refreshed extends TokenRefresh {
  const Refreshed(this.accessToken);

  final String accessToken;
}

/// El servidor rechazó el refresh token (vencido o revocado): la sesión
/// expiró (US03).
final class Rejected extends TokenRefresh {
  const Rejected();
}

/// No se pudo renovar por una causa transitoria (sin red, error del
/// servidor): la sesión se conserva.
final class Unavailable extends TokenRefresh {
  const Unavailable();
}

/// Agrega `Authorization: Bearer` y, ante un 401, intenta **un solo** refresh
/// compartido: si varias peticiones fallan a la vez, todas esperan el mismo
/// refresh. Si funciona, reintenta la petición una vez; si el servidor lo
/// rechaza, avisa con `onSessionExpired` y deja pasar el 401; si no se pudo
/// intentar (sin red), deja pasar el 401 sin cerrar la sesión.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required Dio dio,
    required AuthTokenSource tokens,
    required void Function() onSessionExpired,
    Set<String> publicPaths = defaultPublicPaths,
  }) : _dio = dio,
       _tokens = tokens,
       _onSessionExpired = onSessionExpired,
       _publicPaths = publicPaths;

  /// Rutas que no llevan token ni disparan un refresh. `/device-tokens/
  /// unregister` es la única mutación pública además de `/auth/*` (docs/07):
  /// permite dar de baja el token push después de cerrar sesión.
  static const Set<String> defaultPublicPaths = {
    '/auth/otp',
    '/auth/login',
    '/auth/refresh',
    '/device-tokens/unregister',
  };

  static const _retriedKey = 'quadrapp.auth.retried';

  final Dio _dio;
  final AuthTokenSource _tokens;
  final void Function() _onSessionExpired;
  final Set<String> _publicPaths;

  Future<TokenRefresh>? _refreshing;

  bool _isPublic(RequestOptions options) => _publicPaths.contains(options.path);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = _tokens.accessToken;
    if (token != null && !_isPublic(options)) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final isUnauthorized = err.response?.statusCode == 401;
    if (!isUnauthorized ||
        _isPublic(options) ||
        options.extra[_retriedKey] == true) {
      handler.next(err);
      return;
    }

    final refresh = await (_refreshing ??= _refresh());
    switch (refresh) {
      case Rejected():
        _onSessionExpired();
        handler.next(err);
        return;
      case Unavailable():
        handler.next(err);
        return;
      case Refreshed():
        break;
    }

    try {
      options
        ..extra[_retriedKey] = true
        ..headers['Authorization'] = 'Bearer ${refresh.accessToken}';
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<TokenRefresh> _refresh() async {
    try {
      return await _tokens.refreshAccessToken();
    } on Object {
      return const Unavailable();
    } finally {
      // La siguiente ronda de 401 podrá volver a intentar.
      unawaited(Future<void>.microtask(() => _refreshing = null));
    }
  }
}

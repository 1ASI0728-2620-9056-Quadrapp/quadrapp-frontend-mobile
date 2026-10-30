import 'dart:async';

import 'package:get_it/get_it.dart';

/// Resolvedores de lo registrado con [TrackedRegistration], por localizador.
final Expando<Map<Type, Object Function()>> _resolvers = Expando(
  'di.resolvers',
);

/// Registros que recuerdan qué se registró, para poder comprobar en una prueba
/// que **todo** se construye sin errores (`resolveAll`).
///
/// Los módulos de `app/di` registran siempre con estos ayudantes. Todo es
/// perezoso: construir una dependencia no hace llamadas de red ni toca
/// plugins; eso solo ocurre cuando se usa.
extension TrackedRegistration on GetIt {
  /// Registra [create] como singleton perezoso.
  void addLazy<T extends Object>(
    T Function() create, {
    FutureOr<dynamic> Function(T instance)? dispose,
  }) {
    registerLazySingleton<T>(create, dispose: dispose);
    _track<T>();
  }

  /// Registra un valor ya construido.
  void addValue<T extends Object>(
    T value, {
    FutureOr<dynamic> Function(T instance)? dispose,
  }) {
    registerSingleton<T>(value, dispose: dispose);
    _track<T>();
  }

  void _track<T extends Object>() {
    final tracked = _resolvers[this] ??= {};
    tracked[T] = get<T>;
  }

  /// Los tipos registrados con los ayudantes.
  List<Type> get trackedTypes =>
      List.unmodifiable(_resolvers[this]?.keys ?? const <Type>[]);

  /// Construye todo lo registrado y lo devuelve por tipo. Falla si alguna
  /// dependencia no se puede resolver.
  Map<Type, Object> resolveAll() => {
    for (final entry
        in (_resolvers[this] ?? const <Type, Object Function()>{}).entries)
      entry.key: entry.value(),
  };
}

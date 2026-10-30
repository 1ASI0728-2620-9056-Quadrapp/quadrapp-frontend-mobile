// US02 (esc. 3): nada de un usuario sobrevive al cierre de sesión en un
// dispositivo compartido.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:quadrapp_mobile/app/config/app_config.dart';
import 'package:quadrapp_mobile/app/di/injector.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/repositories/access_token_holder.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/repositories/session_store.dart';
import 'package:quadrapp_mobile/core/session/key_value_resettable.dart';
import 'package:quadrapp_mobile/core/session/resettable.dart';
import 'package:quadrapp_mobile/core/storage/key_value_store.dart';
import 'package:quadrapp_mobile/core/storage/secure_store.dart';

import '../../contexts/iam/support.dart';
import '../../helpers/test_seed.dart';

/// Las dos únicas cosas que guardan algo bajo `device.` y que **no** se borran
/// al cerrar sesión (docs/04): el idioma y la baja pendiente del token push
/// (solo el token del dispositivo, nada del usuario). Se declaran por el nombre
/// del archivo que las guarda.
const _deviceExceptions = {
  // El idioma lo guarda la fase 6 (`device.language`): aún no hay archivo.
  'pending_push_token_removal_store_impl.dart',
};

final _heldStore = RegExp(r'final\s+(KeyValueStore|SecureStore)\s+\w+;');
final _storeKeyPrefix = RegExp(r'StoreKeys\.(\w+)');
final _resettableClass = RegExp(
  r'class\s+(\w+)\s+(?:implements|extends|with)[^{]*\bResettable\b',
);

String _withoutComments(String source) =>
    source.split('\n').where((l) => !l.trimLeft().startsWith('//')).join('\n');

/// Los archivos de `lib/` que guardan un almacén (`KeyValueStore` o
/// `SecureStore`), sin los almacenes mismos ni la raíz de composición.
List<(String path, String source)> _storeHolders() {
  final holders = <(String, String)>[];
  for (final entity in Directory('lib').listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    final path = entity.path.replaceAll(r'\', '/');
    if (path.startsWith('lib/app/di/') ||
        path.startsWith('lib/core/storage/') ||
        path.startsWith('lib/core/session/')) {
      continue;
    }
    final source = _withoutComments(entity.readAsStringSync());
    if (_heldStore.hasMatch(source)) holders.add((path, source));
  }
  return holders;
}

void main() {
  late GetIt locator;
  late InMemoryKeyValueStore values;
  late InMemorySecureStore secrets;
  late ResettableRegistry registry;

  setUp(() async {
    locator = GetIt.asNewInstance();
    values = InMemoryKeyValueStore();
    secrets = InMemorySecureStore();
    await configureDependencies(
      config: const AppConfig(useMocks: true, apiBaseUrl: 'https://x.test'),
      locator: locator,
      keyValueStore: values,
      secureStore: secrets,
      mockSeed: testSeed,
    );
    registry = locator<ResettableRegistry>();
  });

  tearDown(() => locator.reset());

  Set<String> coveredPrefixes() => registry.items
      .whereType<KeyValueResettable>()
      .expand((r) => r.prefixes)
      .toSet();
  Set<String> registeredTypes() =>
      registry.items.map((r) => r.runtimeType.toString()).toSet();

  test('todo almacén que guarda datos de usuario es Resettable', () {
    final holders = _storeHolders();
    // La prueba no se vuelve inútil si cambia la estructura de carpetas.
    expect(holders, isNotEmpty);

    final problems = <String>[];
    for (final (path, source) in holders) {
      final file = path.split('/').last;
      final classes = _resettableClass
          .allMatches(source)
          .map((m) => m.group(1)!)
          .toSet();
      final prefixes = _storeKeyPrefix
          .allMatches(source)
          .map((m) => m.group(1)!)
          .toSet();
      final selfRegistered =
          classes.isNotEmpty && classes.every(registeredTypes().contains);

      if (source.contains(RegExp(r'final\s+SecureStore\s'))) {
        // Los secretos no tienen prefijo: solo vale que el propio almacén sea
        // Resettable y esté registrado.
        if (!selfRegistered) {
          problems.add('$path guarda secretos y no está registrado Resettable');
        }
        continue;
      }
      if (prefixes.isEmpty && !selfRegistered) {
        problems.add('$path guarda claves sin prefijo de StoreKeys');
      }
      for (final prefix in prefixes) {
        switch (prefix) {
          case 'user' || 'cache':
            if (!selfRegistered && !coveredPrefixes().contains('$prefix.')) {
              problems.add('$path guarda `$prefix.` y nada lo limpia');
            }
          case 'device':
            if (!_deviceExceptions.contains(file)) {
              problems.add(
                '$path guarda `device.` y no es excepción declarada',
              );
            }
          default:
            problems.add('$path usa un prefijo desconocido: $prefix');
        }
      }
    }

    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('todo Resettable del código está en la lista de app/di', () {
    final declared = <String>{};
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      declared.addAll(
        _resettableClass
            .allMatches(_withoutComments(entity.readAsStringSync()))
            .map((m) => m.group(1)!),
      );
    }

    expect(declared, isNotEmpty);
    expect(registeredTypes(), containsAll(declared));
  });

  test('las excepciones declaradas existen y siguen sin limpiarse', () {
    final files = _storeHolders().map((h) => h.$1.split('/').last).toSet();
    expect(
      files,
      containsAll(_deviceExceptions),
      reason: 'Una excepción declarada ya no existe: quítala de la lista.',
    );
    expect(coveredPrefixes(), isNot(contains(StoreKeys.device)));
  });

  test(
    'cerrar sesión borra lo del usuario y conserva solo las excepciones',
    () async {
      await locator<SessionStore>().save(sampleStored());
      locator<AccessTokenHolder>().replace(accessToken());
      await values.setString('user.selectedLot', '2');
      await values.setString('user.pushToken', 'fcm:mio');
      await values.setString('cache.layout.1', '{}');
      await values.setString('cache.occupancy.1', '{}');
      await values.setString('device.language', 'es');
      await values.setString('device.pendingPushTokenRemoval', 'fcm:viejo');

      await registry.resetAll();

      expect(await locator<SessionStore>().read(), isNull);
      expect(await secrets.read('refreshToken'), isNull);
      expect(locator<AccessTokenHolder>().current, isNull);
      for (final key in [
        'user.selectedLot',
        'user.pushToken',
        'cache.layout.1',
        'cache.occupancy.1',
      ]) {
        expect(await values.getString(key), isNull, reason: key);
      }
      expect(await values.getString('device.language'), 'es');
      expect(
        await values.getString('device.pendingPushTokenRemoval'),
        'fcm:viejo',
      );
    },
  );
}

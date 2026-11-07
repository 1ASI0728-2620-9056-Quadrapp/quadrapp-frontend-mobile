import 'package:shared_preferences/shared_preferences.dart';

/// Prefijos de las claves, para poder borrar por grupo.
abstract final class StoreKeys {
  /// Datos de un usuario en caché (layout, última ocupación). Se borran al
  /// cerrar sesión.
  static const String cache = 'cache.';

  /// Datos de un usuario que no son caché (estacionamiento elegido).
  static const String user = 'user.';

  /// Preferencias del dispositivo. Sobreviven al cierre de sesión (idioma).
  static const String device = 'device.';
}

/// Almacén clave-valor pequeño para cachés y preferencias.
abstract interface class KeyValueStore {
  Future<String?> getString(String key);

  Future<void> setString(String key, String value);

  Future<void> remove(String key);

  /// Borra todas las claves que empiezan con [prefix].
  Future<void> removeByPrefix(String prefix);
}

/// Implementación con `shared_preferences`.
class SharedPreferencesStore implements KeyValueStore {
  const SharedPreferencesStore(this._preferences);

  final SharedPreferencesAsync _preferences;

  @override
  Future<String?> getString(String key) => _preferences.getString(key);

  @override
  Future<void> setString(String key, String value) =>
      _preferences.setString(key, value);

  @override
  Future<void> remove(String key) => _preferences.remove(key);

  @override
  Future<void> removeByPrefix(String prefix) async {
    final keys = await _preferences.getKeys();
    for (final key in keys.where((k) => k.startsWith(prefix))) {
      await _preferences.remove(key);
    }
  }
}

/// Implementación en memoria (mocks y pruebas).
class InMemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> _data = {};

  @override
  Future<String?> getString(String key) async => _data[key];

  @override
  Future<void> setString(String key, String value) async => _data[key] = value;

  @override
  Future<void> remove(String key) async => _data.remove(key);

  @override
  Future<void> removeByPrefix(String prefix) async =>
      _data.removeWhere((key, _) => key.startsWith(prefix));
}

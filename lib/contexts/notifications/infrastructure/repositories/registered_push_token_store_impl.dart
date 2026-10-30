import 'package:quadrapp_mobile/contexts/notifications/domain/repositories/registered_push_token_store.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/value_objects/push_token.dart';
import 'package:quadrapp_mobile/core/storage/key_value_store.dart';

/// Guarda el token registrado en el `KeyValueStore` (prefijo `user.`: se
/// borra al cerrar sesión).
class RegisteredPushTokenStoreImpl implements RegisteredPushTokenStore {
  const RegisteredPushTokenStoreImpl(this._store);

  final KeyValueStore _store;

  static const _key = '${StoreKeys.user}pushToken';

  @override
  Future<PushToken?> read() async {
    final raw = await _store.getString(_key);
    return raw == null ? null : PushToken.create(raw).valueOrNull;
  }

  @override
  Future<void> save(PushToken token) => _store.setString(_key, token.value);

  @override
  Future<void> clear() => _store.remove(_key);
}

import 'package:quadrapp_mobile/contexts/notifications/domain/repositories/pending_push_token_removal_store.dart';
import 'package:quadrapp_mobile/contexts/notifications/domain/value_objects/push_token.dart';
import 'package:quadrapp_mobile/core/storage/key_value_store.dart';

/// Guarda la baja pendiente en el `KeyValueStore` bajo el prefijo `device.`
/// (no `user.`): no se borra al cerrar sesión. Contiene solo el token push.
class PendingPushTokenRemovalStoreImpl implements PendingPushTokenRemovalStore {
  const PendingPushTokenRemovalStoreImpl(this._store);

  final KeyValueStore _store;

  /// `device.pendingPushTokenRemoval`.
  static const key = '${StoreKeys.device}pendingPushTokenRemoval';

  @override
  Future<PushToken?> read() async {
    final raw = await _store.getString(key);
    return raw == null ? null : PushToken.create(raw).valueOrNull;
  }

  @override
  Future<void> save(PushToken token) => _store.setString(key, token.value);

  @override
  Future<void> clear() => _store.remove(key);
}

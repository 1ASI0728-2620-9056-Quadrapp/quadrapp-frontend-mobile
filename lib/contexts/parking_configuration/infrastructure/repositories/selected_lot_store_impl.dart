import 'package:quadrapp_mobile/contexts/parking_configuration/domain/repositories/selected_lot_store.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/storage/key_value_store.dart';

/// Guarda el estacionamiento elegido en el `KeyValueStore` (prefijo `user.`:
/// se borra al cerrar sesión).
class SelectedLotStoreImpl implements SelectedLotStore {
  const SelectedLotStoreImpl(this._store);

  final KeyValueStore _store;

  static const _key = '${StoreKeys.user}selectedLot';

  @override
  Future<LotId?> read() async {
    final raw = await _store.getString(_key);
    final id = raw == null ? null : int.tryParse(raw);
    return id == null ? null : LotId(id);
  }

  @override
  Future<void> save(LotId lotId) => _store.setString(_key, '${lotId.value}');

  @override
  Future<void> clear() => _store.remove(_key);
}

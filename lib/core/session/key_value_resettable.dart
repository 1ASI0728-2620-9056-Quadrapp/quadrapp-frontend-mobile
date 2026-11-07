import 'package:quadrapp_mobile/core/session/resettable.dart';
import 'package:quadrapp_mobile/core/storage/key_value_store.dart';

/// Borra del `KeyValueStore` todo lo que lleva alguno de los prefijos dados.
///
/// Al cerrar sesión se registra con `StoreKeys.user` y `StoreKeys.cache`:
/// cualquier dato de usuario nuevo que se guarde bajo esos prefijos se limpia
/// sin tocar código. `StoreKeys.device` (el idioma y la baja pendiente del
/// token push) no se registra, así que se conserva.
class KeyValueResettable implements Resettable {
  const KeyValueResettable(this._store, this._prefixes);

  final KeyValueStore _store;
  final List<String> _prefixes;

  /// Los prefijos que borra (la prueba de almacenes reiniciables los revisa).
  List<String> get prefixes => List.unmodifiable(_prefixes);

  @override
  Future<void> reset() async {
    for (final prefix in _prefixes) {
      await _store.removeByPrefix(prefix);
    }
  }
}

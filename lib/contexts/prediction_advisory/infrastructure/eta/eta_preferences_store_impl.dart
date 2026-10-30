import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/entities/eta_preferences.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/repositories/eta_preferences_store.dart';
import 'package:quadrapp_mobile/core/storage/key_value_store.dart';

/// Guarda las preferencias del ETA en el `KeyValueStore` (prefijo `user.`: se
/// borran al cerrar sesión).
class EtaPreferencesStoreImpl implements EtaPreferencesStore {
  const EtaPreferencesStoreImpl(this._store);

  final KeyValueStore _store;

  static const _autoKey = '${StoreKeys.user}eta.auto';
  static const _trafficKey = '${StoreKeys.user}eta.traffic';

  @override
  Future<EtaPreferences> read() async {
    final auto = await _store.getString(_autoKey);
    final traffic = await _store.getString(_trafficKey);
    return EtaPreferences(
      // Sin nada guardado: automático encendido y tráfico apagado.
      autoEnabled: auto != 'false',
      trafficEnabled: traffic == 'true',
    );
  }

  @override
  Future<void> save(EtaPreferences preferences) async {
    await _store.setString(_autoKey, '${preferences.autoEnabled}');
    await _store.setString(_trafficKey, '${preferences.trafficEnabled}');
  }
}

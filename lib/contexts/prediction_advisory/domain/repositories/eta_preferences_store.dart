import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/entities/eta_preferences.dart';

/// Las preferencias del ETA guardadas en el teléfono.
abstract interface class EtaPreferencesStore {
  /// Lo guardado, o los valores por defecto si no hay nada.
  Future<EtaPreferences> read();

  Future<void> save(EtaPreferences preferences);
}

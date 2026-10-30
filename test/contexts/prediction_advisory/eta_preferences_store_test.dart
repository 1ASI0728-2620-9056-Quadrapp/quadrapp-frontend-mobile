// US13, US14: las preferencias del ETA viven en el teléfono y se borran al
// cerrar sesión con el resto del prefijo `user.`.
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/application/usecases/eta_preferences_usecases.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/entities/eta_preferences.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/repositories/eta_preferences_store.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/infrastructure/eta/eta_preferences_store_impl.dart';
import 'package:quadrapp_mobile/core/storage/key_value_store.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

class _FailingStore extends Mock implements EtaPreferencesStore {}

void main() {
  late InMemoryKeyValueStore values;
  late EtaPreferencesStoreImpl store;

  setUp(() {
    values = InMemoryKeyValueStore();
    store = EtaPreferencesStoreImpl(values);
  });

  test('sin nada guardado: automático encendido y tráfico apagado', () async {
    final preferences = await store.read();

    expect(preferences.autoEnabled, isTrue);
    expect(preferences.trafficEnabled, isFalse);
  });

  test('lo guardado se lee igual', () async {
    await store.save(
      const EtaPreferences(autoEnabled: false, trafficEnabled: true),
    );

    final preferences = await store.read();

    expect(preferences.autoEnabled, isFalse);
    expect(preferences.trafficEnabled, isTrue);
  });

  test('cerrar sesión las borra con el prefijo user.', () async {
    await store.save(const EtaPreferences(trafficEnabled: true));

    await values.removeByPrefix(StoreKeys.user);
    final preferences = await store.read();

    expect(preferences, const EtaPreferences());
  });

  group('casos de uso', () {
    test('guardan y leen las preferencias', () async {
      await SaveEtaPreferences(store)(
        const EtaPreferences(trafficEnabled: true),
      );

      final result = await GetEtaPreferences(store)(const NoParams());

      expect(result.valueOrNull?.trafficEnabled, isTrue);
    });

    test('si no se pueden leer, los valores por defecto (sin error)', () async {
      final failing = _FailingStore();
      when(failing.read).thenThrow(StateError('disco'));

      final result = await GetEtaPreferences(failing)(const NoParams());

      expect(result.valueOrNull, const EtaPreferences());
    });
  });
}

// TS16 (idioma de la app)
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/composition/language/language_cubit.dart';
import 'package:quadrapp_mobile/core/storage/key_value_store.dart';

void main() {
  late InMemoryKeyValueStore values;

  setUp(() => values = InMemoryKeyValueStore());

  LanguageCubit build() => LanguageCubit(LanguagePreferenceStore(values));

  test('sin preferencia guardada arranca en inglés', () async {
    final cubit = build();
    await cubit.load();
    expect(cubit.state, AppLanguage.en);
    await cubit.close();
  });

  test('la preferencia guardada manda', () async {
    await values.setString(LanguagePreferenceStore.key, 'es');
    final cubit = build();
    await cubit.load();
    expect(cubit.state, AppLanguage.es);
    await cubit.close();
  });

  test('un código guardado desconocido es inglés', () async {
    await values.setString(LanguagePreferenceStore.key, 'fr');
    final cubit = build();
    await cubit.load();
    expect(cubit.state, AppLanguage.en);
    await cubit.close();
  });

  blocTest<LanguageCubit, AppLanguage>(
    'elegir español lo aplica y lo guarda bajo device.',
    build: build,
    act: (cubit) => cubit.select(AppLanguage.es),
    expect: () => [AppLanguage.es],
    verify: (_) async {
      expect(LanguagePreferenceStore.key, startsWith(StoreKeys.device));
      expect(await values.getString(LanguagePreferenceStore.key), 'es');
    },
  );
}

// TS16 (idioma de la app y de la API)
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quadrapp_mobile/core/storage/key_value_store.dart';

/// Idiomas que el usuario puede elegir: inglés (por defecto) y español.
enum AppLanguage {
  en('en'),
  es('es');

  const AppLanguage(this.code);

  /// Código de `Locale.languageCode`.
  final String code;

  Locale get locale => Locale(code);

  /// El idioma con ese código; cualquier otro (o ninguno) es inglés.
  static AppLanguage fromCode(String? code) =>
      values.firstWhere((l) => l.code == code, orElse: () => AppLanguage.en);
}

/// La preferencia de idioma, guardada solo en el dispositivo
/// (`device.language`). Es de las pocas cosas que sobreviven al cierre de
/// sesión (docs/04).
class LanguagePreferenceStore {
  const LanguagePreferenceStore(this._store);

  static const String key = '${StoreKeys.device}language';

  final KeyValueStore _store;

  Future<AppLanguage?> read() async {
    final code = await _store.getString(key);
    return code == null ? null : AppLanguage.fromCode(code);
  }

  Future<void> write(AppLanguage language) =>
      _store.setString(key, language.code);
}

/// El idioma de la app. Sin preferencia guardada es inglés, sin importar el
/// idioma del teléfono; la preferencia elegida en Ajustes manda y se aplica al
/// instante (textos, fechas y `Accept-Language`).
class LanguageCubit extends Cubit<AppLanguage> {
  LanguageCubit(this._store) : super(AppLanguage.en);

  final LanguagePreferenceStore _store;

  /// Lee la preferencia guardada. Si no se puede leer, sigue en inglés.
  Future<void> load() async {
    try {
      final saved = await _store.read();
      if (saved != null && !isClosed) emit(saved);
    } on Object {
      // Sin preferencia legible: el idioma por defecto.
    }
  }

  /// Cambia el idioma y lo guarda. Si no se puede guardar, el cambio vale
  /// igual para esta sesión de la app.
  Future<void> select(AppLanguage language) async {
    if (language == state) return;
    emit(language);
    try {
      await _store.write(language);
    } on Object {
      // Se aplica igual; el próximo arranque volverá al guardado.
    }
  }
}

/// Mapeo del idioma de la app al valor que espera la API (TS16): `en` →
/// `en-US` y `es` → `es-419`. Cualquier otro idioma usa el inglés.
String apiLanguageTag(String languageCode) => switch (languageCode) {
  'es' => 'es-419',
  _ => 'en-US',
};

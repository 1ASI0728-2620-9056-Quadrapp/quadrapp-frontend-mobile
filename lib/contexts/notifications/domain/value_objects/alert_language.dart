/// Idioma en el que el servidor redacta las alertas: el de la app (`en` o
/// `es`). En la API viaja como `en-US` o `es-419`; ese mapeo vive en
/// `infrastructure`.
enum AlertLanguage {
  en('en'),
  es('es');

  const AlertLanguage(this.code);

  /// Código del idioma de la app (el de `Locale.languageCode`).
  final String code;
}

import 'dart:ui';

/// Idioma por defecto de la app: inglés.
const defaultLocale = Locale('en');

/// Idiomas soportados: inglés y español.
const supportedLanguageCodes = {'en', 'es'};

/// Idioma que se muestra: la preferencia del usuario si es un idioma
/// soportado; en cualquier otro caso (sin preferencia, o un idioma no
/// soportado), inglés.
///
/// El idioma del teléfono no interviene: el primer arranque siempre es en
/// inglés. La preferencia elegida en Ajustes (fase 6) se guarda y tiene
/// prioridad.
Locale resolveLocale(Locale? preferred) {
  if (preferred == null) return defaultLocale;
  return supportedLanguageCodes.contains(preferred.languageCode)
      ? Locale(preferred.languageCode)
      : defaultLocale;
}

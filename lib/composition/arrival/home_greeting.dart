// US04 (saludo de Inicio, del diseño)

/// Parte del día para el saludo de Inicio.
enum GreetingPeriod { morning, afternoon, evening }

/// La parte del día de [limaHour] (0 a 23, hora de pared de Lima): de 5:00 a
/// 11:59 mañana, de 12:00 a 18:59 tarde y el resto noche.
GreetingPeriod greetingPeriodFor(int limaHour) {
  if (limaHour >= 5 && limaHour < 12) return GreetingPeriod.morning;
  if (limaHour >= 12 && limaHour < 19) return GreetingPeriod.afternoon;
  return GreetingPeriod.evening;
}

List<String> _words(String? fullName) => (fullName ?? '')
    .trim()
    .split(RegExp(r'\s+'))
    .where((w) => w.isNotEmpty)
    .toList();

/// La primera palabra del nombre completo de la sesión; `null` si no hay
/// nombre (entonces se saluda sin nombre). **Nunca se deriva del correo.**
String? firstNameOf(String? fullName) {
  final words = _words(fullName);
  return words.isEmpty ? null : words.first;
}

/// Las iniciales del avatar: la primera letra de la primera y de la última
/// palabra del nombre completo, en mayúscula. Con una sola palabra, una letra;
/// sin nombre, `null` (el avatar muestra un ícono de persona).
String? initialsOf(String? fullName) {
  final words = _words(fullName);
  if (words.isEmpty) return null;
  String letter(String word) =>
      String.fromCharCode(word.runes.first).toUpperCase();
  if (words.length == 1) return letter(words.first);
  return letter(words.first) + letter(words.last);
}

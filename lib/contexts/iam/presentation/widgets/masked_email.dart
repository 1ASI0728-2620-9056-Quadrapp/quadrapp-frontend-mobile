// US01 (esc. 2): el código se envió a un correo, sin mostrarlo entero.

/// El correo con la parte local oculta: `camila.rojas@upc.edu.pe` queda
/// `c•••@upc.edu.pe`. Solo se ve la primera letra y el dominio, que es lo que
/// ayuda a reconocer a qué correo se envió el código.
String maskEmail(String email) {
  final at = email.lastIndexOf('@');
  if (at <= 0) return email;
  final first = String.fromCharCode(email.runes.first);
  return '$first•••${email.substring(at)}';
}

/// La primera letra y el dominio de [email] por separado, para anunciar el
/// correo oculto con palabras («c seguido de caracteres ocultos, en
/// upc.edu.pe») en vez de leer los puntos.
({String first, String domain}) emailHint(String email) {
  final at = email.lastIndexOf('@');
  if (at <= 0) return (first: email, domain: '');
  return (
    first: String.fromCharCode(email.runes.first),
    domain: email.substring(at + 1),
  );
}

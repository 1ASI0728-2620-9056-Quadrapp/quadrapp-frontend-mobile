/// Espaciado sobre una base de 4 dp.
abstract final class QaSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
  static const double huge = 64;

  /// Margen lateral de las pantallas (el diseño usa 16 dp).
  static const double screen = 16;

  /// Objetivo táctil mínimo (Android / WCAG 2.2).
  static const double minTapTarget = 48;
}

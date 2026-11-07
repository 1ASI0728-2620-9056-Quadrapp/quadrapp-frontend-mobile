import 'package:flutter/material.dart';

/// Familia tipográfica incluida como asset (no se usa `google_fonts`): Inter,
/// en cuatro pesos (400, 500, 600 y 700) cortados a latino.
abstract final class QaFonts {
  /// Títulos, cifras y etiquetas. En el diseño los títulos van en peso regular
  /// y solo los botones, las etiquetas y las cifras de énfasis son más
  /// gruesos.
  static const String display = 'Inter';

  /// Cuerpo, formularios y listas.
  static const String body = 'Inter';
}

/// Escala tipográfica del diseño, en sp. El texto más pequeño es de 12 sp (el
/// diseño trae algunos de 11: se sube un punto por legibilidad) y todo escala
/// con el ajuste del sistema hasta el 200 %.
abstract final class QaTextStyles {
  static const double size12 = 12;
  static const double size13 = 13;
  static const double size14 = 14;
  static const double size15 = 15;
  static const double size16 = 16;
  static const double size17 = 17;
  static const double size22 = 22;
  static const double size24 = 24;
  static const double size26 = 26;
  static const double size30 = 30;
  static const double size32 = 32;
  static const double size40 = 40;

  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  /// Cuerpo base (16 sp, interlineado 1,5).
  static const TextStyle body = TextStyle(
    fontFamily: QaFonts.body,
    fontSize: size16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  /// Convierte los números en cifras tabulares (contadores que no "bailan").
  static TextStyle tabular(TextStyle style) =>
      style.copyWith(fontFeatures: _tabular);

  /// `TextTheme` de la app. Los colores los pone el `ThemeData`.
  static TextTheme textTheme() {
    const regular = TextStyle(
      fontFamily: QaFonts.display,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.2,
    );
    const medium = TextStyle(
      fontFamily: QaFonts.display,
      fontWeight: FontWeight.w500,
    );
    const strong = TextStyle(
      fontFamily: QaFonts.display,
      fontWeight: FontWeight.w600,
      height: 1.3,
    );
    const number = TextStyle(
      fontFamily: QaFonts.display,
      fontWeight: FontWeight.w700,
      fontFeatures: _tabular,
    );
    return TextTheme(
      // Cifras grandes (el porcentaje del héroe, los libres del anillo).
      displayLarge: number.copyWith(fontSize: size40, height: 1.1),
      displayMedium: number.copyWith(fontSize: size32, height: 1.1),
      displaySmall: number.copyWith(fontSize: size24, height: 1.15),
      // Titulares de pantalla: peso regular, como en el diseño.
      headlineLarge: regular.copyWith(fontSize: size30, height: 1.2),
      headlineMedium: regular.copyWith(fontSize: size26, height: 1.25),
      headlineSmall: regular.copyWith(fontSize: size22, height: 1.3),
      titleLarge: regular.copyWith(fontSize: size24, height: 1.25),
      titleMedium: medium.copyWith(fontSize: size17, height: 1.3),
      titleSmall: medium.copyWith(fontSize: size15, height: 1.35),
      bodyLarge: body,
      bodyMedium: body.copyWith(fontSize: size14, height: 1.45),
      bodySmall: body.copyWith(fontSize: size12, height: 1.4),
      labelLarge: strong.copyWith(fontSize: size15),
      labelMedium: strong.copyWith(fontSize: size13),
      labelSmall: medium.copyWith(fontSize: size12, height: 1.3),
    );
  }
}

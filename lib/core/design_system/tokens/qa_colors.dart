import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_tone.dart';

/// Tokens de color propios, con variante clara y oscura. Se leen con
/// `context.qaColors`. La paleta sale del diseño de Figma: petróleo (marca y
/// texto), teal (acción), verde (libre), ámbar (limitada y sin datos), rojo
/// (lleno y errores) y neutros de menta fría.
///
/// Cada tono de estado tiene tres colores: el del texto y los íconos
/// ([accent]), el de las barras y los glifos ([graphic]) y su fondo suave
/// ([fill]), que lleva texto [accent].
///
/// Reglas de contraste (verificadas en `qa_colors_contrast_test.dart`, claro y
/// oscuro):
/// - Texto: 4.5:1, también el atenuado ([onSurfaceMuted]) sobre cada fondo
///   suave. Componentes gráficos: 3:1.
/// - El borde de un campo, una casilla o un interruptor usa [outline] (3:1);
///   los bordes decorativos ([paint]) no son controles.
/// - El estado nunca se comunica solo con color: siempre ícono + texto (y
///   rayado para sin datos).
@immutable
class QaColors extends ThemeExtension<QaColors> {
  const QaColors({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.onSurface,
    required this.onSurfaceMuted,
    required this.outline,
    required this.paint,
    required this.primary,
    required this.onPrimary,
    required this.primaryDark,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.free,
    required this.freeGraphic,
    required this.freeFill,
    required this.mint,
    required this.onMint,
    required this.limited,
    required this.limitedText,
    required this.limitedFill,
    required this.ink,
    required this.full,
    required this.alertFill,
    required this.onAccent,
    required this.occupied,
    required this.occupiedFill,
    required this.unknown,
    required this.infoFill,
    required this.brand,
    required this.onBrand,
    required this.onBrandMuted,
    required this.brandEnd,
    required this.brandAccent,
    required this.onBrandAccent,
    required this.shadow,
    required this.shadowStrength,
  });

  /// Modo claro.
  static const QaColors light = QaColors(
    background: Color(0xFFF3F7F6),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFE8F0EF),
    onSurface: Color(0xFF073B4C),
    onSurfaceMuted: Color(0xFF4F676F),
    outline: Color(0xFF6F878E),
    paint: Color(0xFFD8E3E2),
    primary: Color(0xFF077B7F),
    onPrimary: Color(0xFFFFFFFF),
    primaryDark: Color(0xFF055F63),
    primaryContainer: Color(0xFFDDF3F1),
    onPrimaryContainer: Color(0xFF073B4C),
    free: Color(0xFF16704D),
    freeGraphic: Color(0xFF16704D),
    freeFill: Color(0xFFDFF3E9),
    mint: Color(0xFFDDF3F1),
    onMint: Color(0xFF073B4C),
    limited: Color(0xFFC47508),
    limitedText: Color(0xFF8A5208),
    limitedFill: Color(0xFFFFF2D6),
    ink: Color(0xFF073B4C),
    full: Color(0xFFB03C3C),
    alertFill: Color(0xFFFCE6E6),
    onAccent: Color(0xFFFFFFFF),
    occupied: Color(0xFF556A72),
    occupiedFill: Color(0xFFE6EDEF),
    unknown: Color(0xFFC47508),
    infoFill: Color(0xFFE2EDF7),
    brand: Color(0xFF073B4C),
    onBrand: Color(0xFFFFFFFF),
    onBrandMuted: Color(0xFFB8C7CC),
    brandEnd: Color(0xFF073B4C),
    brandAccent: Color(0xFFD98617),
    onBrandAccent: Color(0xFF031B24),
    shadow: Color(0xFF073B4C),
    shadowStrength: 1,
  );

  /// Modo oscuro.
  static const QaColors dark = QaColors(
    background: Color(0xFF061B24),
    surface: Color(0xFF0B2B38),
    surfaceMuted: Color(0xFF123B4B),
    onSurface: Color(0xFFE4F0F1),
    onSurfaceMuted: Color(0xFFA3BAC0),
    outline: Color(0xFF6E8E98),
    paint: Color(0xFF1D4455),
    primary: Color(0xFF3FBFC3),
    onPrimary: Color(0xFF04242B),
    primaryDark: Color(0xFF2A9EA2),
    primaryContainer: Color(0xFF0F4A55),
    onPrimaryContainer: Color(0xFFCFEFEF),
    free: Color(0xFF5CD39E),
    freeGraphic: Color(0xFF3DBB84),
    freeFill: Color(0xFF0F3F33),
    mint: Color(0xFF0E4650),
    onMint: Color(0xFFBFF0EE),
    limited: Color(0xFFF2A93B),
    limitedText: Color(0xFFF6C35F),
    limitedFill: Color(0xFF3A2C0E),
    ink: Color(0xFF061B24),
    full: Color(0xFFF28B8B),
    alertFill: Color(0xFF3E1B1F),
    onAccent: Color(0xFF06202A),
    occupied: Color(0xFF9FB3B9),
    occupiedFill: Color(0xFF183A47),
    unknown: Color(0xFFF2A93B),
    infoFill: Color(0xFF12384F),
    brand: Color(0xFF0B4658),
    onBrand: Color(0xFFFFFFFF),
    onBrandMuted: Color(0xFFB8C7CC),
    brandEnd: Color(0xFF0B4658),
    brandAccent: Color(0xFFF6C35F),
    onBrandAccent: Color(0xFF04222B),
    shadow: Color(0xFF000000),
    shadowStrength: 4,
  );

  /// Fondo de las pantallas.
  final Color background;

  /// Tarjetas, barras y hojas.
  final Color surface;

  /// Relleno tonal: pistas, esqueletos y paneles secundarios.
  final Color surfaceMuted;

  /// Texto principal.
  final Color onSurface;

  /// Texto secundario (4.5:1 sobre las superficies y los fondos suaves).
  final Color onSurfaceMuted;

  /// Borde de un control (campo, casilla, interruptor): 3:1.
  final Color outline;

  /// Bordes decorativos, divisores y pistas (no son controles).
  final Color paint;

  /// Acción principal: relleno de botones e interruptores.
  final Color primary;

  /// Texto sobre [primary].
  final Color onPrimary;

  /// [primary] presionado.
  final Color primaryDark;

  /// Relleno tonal de la marca (menta).
  final Color primaryContainer;

  /// Texto sobre [primaryContainer].
  final Color onPrimaryContainer;

  /// Texto e íconos de libre / buena disponibilidad.
  final Color free;

  /// Barras, glifos y anillos de libre (3:1).
  final Color freeGraphic;

  /// Fondo suave de libre (chips y tarjetas), con texto [free].
  final Color freeFill;

  /// Panel tonal informativo (privacidad, ayuda), con texto [onMint].
  final Color mint;

  /// Texto sobre [mint].
  final Color onMint;

  /// Barras y glifos de limitada y de sin datos (3:1).
  final Color limited;

  /// Texto e íconos de limitada / sin datos / advertencia.
  final Color limitedText;

  /// Fondo suave de limitada y de sin datos, con texto [limitedText].
  final Color limitedFill;

  /// Texto sobre rellenos claros fijos.
  final Color ink;

  /// Texto, íconos y barras de lleno / baja / error; relleno destructivo.
  final Color full;

  /// Fondo suave de lleno / baja / error, con texto [full].
  final Color alertFill;

  /// Texto sobre rellenos fuertes ([full], [occupied]).
  final Color onAccent;

  /// Ocupado: un neutro, nunca rojo.
  final Color occupied;

  /// Fondo suave de ocupado, con texto [occupied].
  final Color occupiedFill;

  /// Sin datos: ámbar, siempre con rayado.
  final Color unknown;

  /// Fondo suave informativo (nota de método), con texto [onSurface].
  final Color infoFill;

  /// Superficie de marca (el héroe).
  final Color brand;

  /// Texto sobre [brand].
  final Color onBrand;

  /// Texto secundario sobre [brand] (etiquetas y notas).
  final Color onBrandMuted;

  /// Final del degradado de marca (el diseño es plano: igual a [brand]).
  final Color brandEnd;

  /// Detalle de marca (la plaza resaltada).
  final Color brandAccent;

  /// Texto sobre [brandAccent].
  final Color onBrandAccent;

  /// Color de la sombra, muy difusa.
  final Color shadow;

  /// Intensidad de la sombra (1 en claro, mayor en oscuro).
  final double shadowStrength;

  /// Relleno de las superficies de marca y los héroes. El diseño es plano
  /// (petróleo liso): el degradado va de [brand] a [brandEnd], que son iguales.
  LinearGradient get brandGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brand, brandEnd],
  );

  /// Color de texto y de trazos para [tone] (4.5:1 sobre las superficies y
  /// sobre su [fill]).
  Color accent(QaTone tone) => switch (tone) {
    QaTone.free => free,
    QaTone.limited || QaTone.unknown => limitedText,
    QaTone.full => full,
    QaTone.occupied => occupied,
  };

  /// Color de un gráfico pequeño de [tone] (glifos, barras, anillos): 3:1
  /// sobre las superficies.
  Color graphic(QaTone tone) => switch (tone) {
    QaTone.free => freeGraphic,
    QaTone.limited => limited,
    QaTone.full => full,
    QaTone.occupied => occupied,
    QaTone.unknown => unknown,
  };

  /// Fondo suave de [tone] (chips, tarjetas de horizonte, avisos).
  Color fill(QaTone tone) => switch (tone) {
    QaTone.free => freeFill,
    QaTone.limited || QaTone.unknown => limitedFill,
    QaTone.full => alertFill,
    QaTone.occupied => occupiedFill,
  };

  /// Color del texto que va sobre el [fill] de [tone].
  Color onFill(QaTone tone) => accent(tone);

  @override
  QaColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceMuted,
    Color? onSurface,
    Color? onSurfaceMuted,
    Color? outline,
    Color? paint,
    Color? primary,
    Color? onPrimary,
    Color? primaryDark,
    Color? primaryContainer,
    Color? onPrimaryContainer,
    Color? free,
    Color? freeGraphic,
    Color? freeFill,
    Color? mint,
    Color? onMint,
    Color? limited,
    Color? limitedText,
    Color? limitedFill,
    Color? ink,
    Color? full,
    Color? alertFill,
    Color? onAccent,
    Color? occupied,
    Color? occupiedFill,
    Color? unknown,
    Color? infoFill,
    Color? brand,
    Color? onBrand,
    Color? onBrandMuted,
    Color? brandEnd,
    Color? brandAccent,
    Color? onBrandAccent,
    Color? shadow,
    double? shadowStrength,
  }) {
    return QaColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      onSurface: onSurface ?? this.onSurface,
      onSurfaceMuted: onSurfaceMuted ?? this.onSurfaceMuted,
      outline: outline ?? this.outline,
      paint: paint ?? this.paint,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      primaryDark: primaryDark ?? this.primaryDark,
      primaryContainer: primaryContainer ?? this.primaryContainer,
      onPrimaryContainer: onPrimaryContainer ?? this.onPrimaryContainer,
      free: free ?? this.free,
      freeGraphic: freeGraphic ?? this.freeGraphic,
      freeFill: freeFill ?? this.freeFill,
      mint: mint ?? this.mint,
      onMint: onMint ?? this.onMint,
      limited: limited ?? this.limited,
      limitedText: limitedText ?? this.limitedText,
      limitedFill: limitedFill ?? this.limitedFill,
      ink: ink ?? this.ink,
      full: full ?? this.full,
      alertFill: alertFill ?? this.alertFill,
      onAccent: onAccent ?? this.onAccent,
      occupied: occupied ?? this.occupied,
      occupiedFill: occupiedFill ?? this.occupiedFill,
      unknown: unknown ?? this.unknown,
      infoFill: infoFill ?? this.infoFill,
      brand: brand ?? this.brand,
      onBrand: onBrand ?? this.onBrand,
      onBrandMuted: onBrandMuted ?? this.onBrandMuted,
      brandEnd: brandEnd ?? this.brandEnd,
      brandAccent: brandAccent ?? this.brandAccent,
      onBrandAccent: onBrandAccent ?? this.onBrandAccent,
      shadow: shadow ?? this.shadow,
      shadowStrength: shadowStrength ?? this.shadowStrength,
    );
  }

  @override
  QaColors lerp(ThemeExtension<QaColors>? other, double t) {
    if (other is! QaColors) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return QaColors(
      background: mix(background, other.background),
      surface: mix(surface, other.surface),
      surfaceMuted: mix(surfaceMuted, other.surfaceMuted),
      onSurface: mix(onSurface, other.onSurface),
      onSurfaceMuted: mix(onSurfaceMuted, other.onSurfaceMuted),
      outline: mix(outline, other.outline),
      paint: mix(paint, other.paint),
      primary: mix(primary, other.primary),
      onPrimary: mix(onPrimary, other.onPrimary),
      primaryDark: mix(primaryDark, other.primaryDark),
      primaryContainer: mix(primaryContainer, other.primaryContainer),
      onPrimaryContainer: mix(onPrimaryContainer, other.onPrimaryContainer),
      free: mix(free, other.free),
      freeGraphic: mix(freeGraphic, other.freeGraphic),
      freeFill: mix(freeFill, other.freeFill),
      mint: mix(mint, other.mint),
      onMint: mix(onMint, other.onMint),
      limited: mix(limited, other.limited),
      limitedText: mix(limitedText, other.limitedText),
      limitedFill: mix(limitedFill, other.limitedFill),
      ink: mix(ink, other.ink),
      full: mix(full, other.full),
      alertFill: mix(alertFill, other.alertFill),
      onAccent: mix(onAccent, other.onAccent),
      occupied: mix(occupied, other.occupied),
      occupiedFill: mix(occupiedFill, other.occupiedFill),
      unknown: mix(unknown, other.unknown),
      infoFill: mix(infoFill, other.infoFill),
      brand: mix(brand, other.brand),
      onBrand: mix(onBrand, other.onBrand),
      onBrandMuted: mix(onBrandMuted, other.onBrandMuted),
      brandEnd: mix(brandEnd, other.brandEnd),
      brandAccent: mix(brandAccent, other.brandAccent),
      onBrandAccent: mix(onBrandAccent, other.onBrandAccent),
      shadow: mix(shadow, other.shadow),
      shadowStrength:
          shadowStrength + (other.shadowStrength - shadowStrength) * t,
    );
  }
}

/// Acceso corto a los tokens desde un `BuildContext`.
extension QaColorsContext on BuildContext {
  QaColors get qaColors =>
      Theme.of(this).extension<QaColors>() ?? QaColors.light;
}

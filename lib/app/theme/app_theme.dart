import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_colors.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_radii.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_spacing.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_text_styles.dart';

/// `ThemeData` de la app, con el `ColorScheme` definido a mano (no
/// `ColorScheme.fromSeed`) a partir de los tokens de [QaColors].
abstract final class AppTheme {
  /// Barra inferior del diseño: superficie plana (el borde de 1 dp lo pone el
  /// shell), sin indicador; la pestaña seleccionada lleva el ícono relleno y
  /// la etiqueta en teal; las demás, ícono delineado y etiqueta atenuada.
  /// Contraste de íconos 3:1 y de etiquetas 4.5:1 en claro y oscuro.
  static NavigationBarThemeData _navigationBarTheme(
    QaColors c,
    TextTheme textTheme,
  ) {
    final label = textTheme.labelSmall ?? const TextStyle();
    return NavigationBarThemeData(
      backgroundColor: c.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      height: 72,
      indicatorColor: Colors.transparent,
      indicatorShape: const StadiumBorder(),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 24,
          color: states.contains(WidgetState.selected)
              ? c.primary
              : c.onSurfaceMuted,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? label.copyWith(fontWeight: FontWeight.w600, color: c.primary)
            : label.copyWith(
                fontWeight: FontWeight.w400,
                color: c.onSurfaceMuted,
              ),
      ),
    );
  }

  static ThemeData light() => _build(QaColors.light, Brightness.light);

  static ThemeData dark() => _build(QaColors.dark, Brightness.dark);

  static ThemeData _build(QaColors c, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.onPrimary,
      primaryContainer: c.primaryContainer,
      onPrimaryContainer: c.onPrimaryContainer,
      secondary: c.free,
      onSecondary: c.onPrimary,
      secondaryContainer: c.mint,
      onSecondaryContainer: c.onMint,
      error: c.full,
      onError: c.onAccent,
      surface: c.surface,
      onSurface: c.onSurface,
      onSurfaceVariant: c.onSurfaceMuted,
      surfaceContainerHighest: c.surfaceMuted,
      outline: c.outline,
      outlineVariant: c.paint,
      shadow: c.shadow,
      scrim: const Color(0xFF000000),
      surfaceTint: Colors.transparent,
    );

    final textTheme = QaTextStyles.textTheme().apply(
      bodyColor: c.onSurface,
      displayColor: c.onSurface,
    );

    const border = BorderSide();
    OutlineInputBorder inputBorder(Color color, {double width = 1.5}) =>
        OutlineInputBorder(
          borderRadius: QaRadii.controlRadius,
          borderSide: BorderSide(color: color, width: width),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.background,
      canvasColor: c.background,
      textTheme: textTheme,
      fontFamily: QaFonts.body,
      extensions: [c],
      materialTapTargetSize: MaterialTapTargetSize.padded,
      // Elevación casi plana: se separa por superficie y borde, no por sombra.
      appBarTheme: AppBarTheme(
        backgroundColor: c.surface,
        foregroundColor: c.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleMedium,
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: QaRadii.cardRadius,
          side: border.copyWith(color: c.paint),
        ),
      ),
      dividerTheme: DividerThemeData(color: c.paint, thickness: 1, space: 1),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: QaRadii.surfaceRadius,
          side: border.copyWith(color: c.paint),
        ),
        titleTextStyle: textTheme.titleMedium,
        contentTextStyle: textTheme.bodyLarge,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        // 16 + 24 de línea + 16 = 56 dp de alto.
        contentPadding: const EdgeInsets.symmetric(
          horizontal: QaSpacing.lg,
          vertical: QaSpacing.lg,
        ),
        border: inputBorder(c.outline, width: 1),
        enabledBorder: inputBorder(c.outline, width: 1),
        focusedBorder: inputBorder(c.primary, width: 2),
        errorBorder: inputBorder(c.full),
        focusedErrorBorder: inputBorder(c.full, width: 2),
        disabledBorder: inputBorder(c.paint),
        prefixIconColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.error)
              ? c.full
              : states.contains(WidgetState.focused)
              ? c.primary
              : c.onSurfaceMuted,
        ),
        labelStyle: textTheme.bodyLarge?.copyWith(color: c.onSurfaceMuted),
        floatingLabelStyle: WidgetStateTextStyle.resolveWith(
          (states) => (textTheme.bodyLarge ?? const TextStyle()).copyWith(
            color: states.contains(WidgetState.error)
                ? c.full
                : states.contains(WidgetState.focused)
                ? c.primary
                : c.onSurfaceMuted,
          ),
        ),
        helperStyle: textTheme.bodyMedium?.copyWith(color: c.onSurfaceMuted),
        errorStyle: textTheme.bodyMedium?.copyWith(color: c.full),
      ),
      navigationBarTheme: _navigationBarTheme(c, textTheme),
      // Interruptor del diseño: pista teal con la perilla blanca; apagado, la
      // pista es tonal y lleva el borde `outline` (3:1) para que se vea.
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStatePropertyAll(c.surface),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? c.primary
              : c.surfaceMuted,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.transparent
              : c.outline,
        ),
        trackOutlineWidth: const WidgetStatePropertyAll(1.5),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.onSurface,
        contentTextStyle: textTheme.bodyLarge?.copyWith(color: c.surface),
        behavior: SnackBarBehavior.floating,
        // Sobre el fondo oscuro (claro) o claro (oscuro) del aviso.
        actionTextColor: brightness == Brightness.light ? c.mint : c.brand,
        shape: const RoundedRectangleBorder(
          borderRadius: QaRadii.controlRadius,
        ),
      ),
    );
  }
}

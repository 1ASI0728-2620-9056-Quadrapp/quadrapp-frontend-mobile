import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/core/design_system/components/qa_press_scale.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_colors.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_motion.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_radii.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_spacing.dart';

/// Variantes del botón. [onBrand] es para el héroe de petróleo: relleno blanco
/// con texto petróleo, en ambos modos.
enum QaButtonVariant {
  primary,
  tonal,
  text,
  destructive,

  /// Destructiva de baja insistencia (rojo sobre blanco, con borde): la que
  /// abre una confirmación, como «Cerrar sesión»; la ventana lleva la roja.
  destructiveOutlined,
  onBrand,
}

/// Alto del botón: [regular] (48 dp, el mínimo táctil) o [large] (56 dp, la
/// acción dominante de una pantalla, como "Send code").
enum QaButtonSize {
  regular(QaSpacing.minTapTarget),
  large(56);

  const QaButtonSize(this.height);

  final double height;
}

/// Botón de la app: objetivo táctil mínimo de 48 dp, texto escalable y estado
/// de carga (no deshabilitado a ciegas). Con `onPressed == null` queda
/// deshabilitado.
///
/// Estados distinguibles sin depender de la opacidad ni solo del color:
/// - **normal** y **presionado** (la acción principal pasa a Primary dark y el
///   botón se encoge a 0,98);
/// - **deshabilitado**: relleno gris neutro, texto atenuado y borde de 1,5 dp;
/// - **cargando**: el indicador va a la izquierda y el texto se queda, así que
///   el botón conserva su ancho;
/// - **con foco**: anillo de 2 dp.
class QaButton extends StatelessWidget {
  const QaButton({
    required this.label,
    required this.onPressed,
    this.variant = QaButtonVariant.primary,
    this.size = QaButtonSize.regular,
    this.isLoading = false,
    this.loadingLabel,
    this.icon,
    this.trailingIcon,
    this.expand = false,
    this.color,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final QaButtonVariant variant;
  final QaButtonSize size;

  /// Muestra un indicador de progreso y bloquea el botón.
  final bool isLoading;

  /// Texto mientras carga (por defecto, [label]).
  final String? loadingLabel;
  final IconData? icon;

  /// Ícono después del texto (por ejemplo, la flecha de «Continuar»).
  final IconData? trailingIcon;

  /// Ocupa todo el ancho disponible.
  final bool expand;

  /// Sustituye el color del texto de un botón de texto (por ejemplo, el tono
  /// del aviso en el que va, para que pase el contraste sobre su fondo).
  final Color? color;

  static const double _indicator = 20;

  @override
  Widget build(BuildContext context) {
    final colors = context.qaColors;
    final textStyle = Theme.of(context).textTheme.labelLarge;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (Color background, Color foreground) = switch (variant) {
      QaButtonVariant.primary => (colors.primary, colors.onPrimary),
      QaButtonVariant.tonal => (
        colors.primaryContainer,
        colors.onPrimaryContainer,
      ),
      QaButtonVariant.text => (Colors.transparent, color ?? colors.primary),
      QaButtonVariant.destructive => (colors.full, colors.onAccent),
      QaButtonVariant.destructiveOutlined => (colors.surface, colors.full),
      QaButtonVariant.onBrand => (colors.onBrand, colors.brand),
    };
    // Cargando no es deshabilitado: conserva los colores del botón.
    bool dimmed(Set<WidgetState> states) =>
        states.contains(WidgetState.disabled) && !isLoading;

    final style = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(
        Size(QaSpacing.minTapTarget, size.height),
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: QaSpacing.lg, vertical: QaSpacing.sm),
      ),
      shape: WidgetStateProperty.resolveWith((states) {
        final BorderSide side;
        if (dimmed(states) && variant != QaButtonVariant.text) {
          side = BorderSide(color: colors.outline, width: 1.5);
        } else if (states.contains(WidgetState.focused)) {
          // Sobre el petróleo el anillo de foco es ámbar (3:1 sobre él).
          side = BorderSide(
            color: variant == QaButtonVariant.onBrand
                ? colors.brandAccent
                : colors.onSurface,
            width: 2,
          );
        } else if (variant == QaButtonVariant.destructiveOutlined) {
          side = BorderSide(color: colors.full, width: 1.5);
        } else {
          side = BorderSide.none;
        }
        return RoundedRectangleBorder(
          borderRadius: QaRadii.controlRadius,
          side: side,
        );
      }),
      textStyle: WidgetStatePropertyAll(textStyle),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (dimmed(states)) {
          return variant == QaButtonVariant.text
              ? Colors.transparent
              : colors.surfaceMuted;
        }
        if (states.contains(WidgetState.pressed) &&
            variant != QaButtonVariant.text) {
          // Presionado: en claro la acción principal pasa a Primary dark; el
          // resto (y el modo oscuro) se oscurece.
          if (variant == QaButtonVariant.primary && !isDark) {
            return colors.primaryDark;
          }
          if (variant == QaButtonVariant.destructiveOutlined) {
            return colors.alertFill;
          }
          return Color.alphaBlend(const Color(0x33000000), background);
        }
        return background;
      }),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) => dimmed(states) ? colors.onSurfaceMuted : foreground,
      ),
      overlayColor: WidgetStateProperty.resolveWith(
        (states) =>
            variant == QaButtonVariant.text &&
                states.contains(WidgetState.pressed)
            ? foreground.withValues(alpha: 0.12)
            : Colors.transparent,
      ),
      elevation: const WidgetStatePropertyAll(0),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
    );

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          ExcludeSemantics(
            child: SizedBox.square(
              dimension: _indicator,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: foreground,
                // Sin animación si el usuario la desactivó.
                value: QaMotion.enabled(context) ? null : 0.25,
              ),
            ),
          ),
          const SizedBox(width: QaSpacing.sm),
        ] else if (icon != null) ...[
          Icon(icon, size: _indicator),
          const SizedBox(width: QaSpacing.sm),
        ],
        Flexible(
          child: Text(
            isLoading ? (loadingLabel ?? label) : label,
            textAlign: TextAlign.center,
          ),
        ),
        if (trailingIcon != null && !isLoading) ...[
          const SizedBox(width: QaSpacing.sm),
          Icon(trailingIcon, size: _indicator),
        ],
      ],
    );

    final callback = isLoading ? null : onPressed;
    final button = variant == QaButtonVariant.text
        ? TextButton(onPressed: callback, style: style, child: content)
        : FilledButton(onPressed: callback, style: style, child: content);

    final pressable = QaPressScale(
      enabled: onPressed != null && !isLoading,
      child: button,
    );
    return expand
        ? SizedBox(width: double.infinity, child: pressable)
        : pressable;
  }
}

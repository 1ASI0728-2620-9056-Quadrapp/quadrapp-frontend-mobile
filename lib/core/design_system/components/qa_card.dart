import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/core/design_system/components/qa_press_scale.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_colors.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_elevation.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_radii.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_spacing.dart';

/// Superficie de la app: tarjeta de 20 dp de radio con borde de 1 dp y una
/// elevación suave de dos niveles ([QaElevationLevel]).
///
/// Con [hero] la superficie es de marca: degradado de Primary dark a Primary
/// (solo en héroes y superficies de marca, nunca en texto ni en botones), sin
/// borde, y el texto de dentro debe ser `onBrand`.
///
/// Con [onTap] la tarjeta entera es **un solo objetivo táctil**: se encoge a
/// 0,98 al tocarla, muestra la ondulación dentro de sus esquinas y, si se da
/// [semanticLabel], se anuncia como un botón con ese resumen (lo de dentro no
/// se anuncia por separado).
class QaCard extends StatelessWidget {
  const QaCard({
    required this.child,
    this.elevation = QaElevationLevel.low,
    this.padding = const EdgeInsets.all(QaSpacing.lg),
    this.hero = false,
    this.borderColor,
    this.onTap,
    this.onLongPress,
    this.semanticLabel,
    this.semanticHint,
    super.key,
  });

  final Widget child;
  final QaElevationLevel elevation;
  final EdgeInsetsGeometry padding;
  final bool hero;

  /// Sustituye el borde (por ejemplo, el tono de advertencia de un dato
  /// vencido).
  final Color? borderColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? semanticLabel;
  final String? semanticHint;

  @override
  Widget build(BuildContext context) {
    final colors = context.qaColors;
    final decoration = BoxDecoration(
      color: hero ? null : colors.surface,
      gradient: hero ? colors.brandGradient : null,
      borderRadius: QaRadii.cardRadius,
      border: hero ? null : Border.all(color: borderColor ?? colors.paint),
      boxShadow: QaElevation.of(
        colors,
        hero ? QaElevationLevel.high : elevation,
      ),
    );

    if (onTap == null && onLongPress == null) {
      return DecoratedBox(
        decoration: decoration,
        child: Padding(padding: padding, child: child),
      );
    }

    final card = DecoratedBox(
      decoration: decoration,
      child: Material(
        type: MaterialType.transparency,
        borderRadius: QaRadii.cardRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: QaRadii.cardRadius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
    final pressable = QaPressScale(child: card);
    if (semanticLabel == null) return pressable;
    return Semantics(
      container: true,
      button: true,
      label: semanticLabel,
      hint: semanticHint,
      onTap: onTap,
      onLongPress: onLongPress,
      excludeSemantics: true,
      child: pressable,
    );
  }
}

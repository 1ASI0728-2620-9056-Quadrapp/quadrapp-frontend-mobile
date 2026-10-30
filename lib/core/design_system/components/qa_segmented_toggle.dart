import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_colors.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_elevation.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_motion.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_radii.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_spacing.dart';

/// Una opción de [QaSegmentedToggle]: siempre con texto (el ícono es apoyo).
class QaSegment<T> {
  const QaSegment({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// Opciones excluyentes como en el Figma: un carril atenuado y la opción
/// elegida sobre una pastilla blanca elevada, en teal y semibold. Lo elegido
/// se distingue por superficie, peso y color (no solo por color) y se anuncia
/// como seleccionado. Sin animaciones si el sistema las desactiva.
class QaSegmentedToggle<T> extends StatelessWidget {
  const QaSegmentedToggle({
    required this.segments,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<QaSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.qaColors;
    final theme = Theme.of(context);
    final duration = QaMotion.of(context, QaMotion.resize);
    const inset = QaSpacing.xs;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: QaRadii.controlRadius,
      ),
      child: Padding(
        padding: const EdgeInsets.all(inset),
        child: Row(
          children: [
            for (final segment in segments)
              Expanded(
                child: _SegmentButton(
                  segment: segment,
                  selected: segment.value == selected,
                  duration: duration,
                  onTap: () => onChanged(segment.value),
                  colors: colors,
                  textStyle: theme.textTheme.labelLarge,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SegmentButton<T> extends StatelessWidget {
  const _SegmentButton({
    required this.segment,
    required this.selected,
    required this.duration,
    required this.onTap,
    required this.colors,
    required this.textStyle,
  });

  final QaSegment<T> segment;
  final bool selected;
  final Duration duration;
  final VoidCallback onTap;
  final QaColors colors;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    final foreground = selected ? colors.primary : colors.onSurfaceMuted;
    const radius = BorderRadius.all(
      Radius.circular(QaRadii.control - QaSpacing.xs),
    );
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      excludeSemantics: true,
      label: segment.label,
      onTap: onTap,
      child: AnimatedContainer(
        duration: duration,
        curve: Curves.easeOut,
        constraints: const BoxConstraints(
          minHeight: QaSpacing.minTapTarget,
        ),
        decoration: BoxDecoration(
          color: selected ? colors.surface : colors.surfaceMuted,
          borderRadius: radius,
          boxShadow: selected
              ? QaElevation.of(colors, QaElevationLevel.low)
              : const [],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: selected ? null : onTap,
            borderRadius: radius,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: QaSpacing.md,
                vertical: QaSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (segment.icon != null) ...[
                    Icon(segment.icon, size: 18, color: foreground),
                    const SizedBox(width: QaSpacing.sm),
                  ],
                  Flexible(
                    child: Text(
                      segment.label,
                      overflow: TextOverflow.ellipsis,
                      style: textStyle?.copyWith(
                        color: foreground,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_colors.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_spacing.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_tone.dart';

/// Píldora de estado del diseño ("Buena disponibilidad", "Limitada"): fondo
/// suave del tono, texto en negrita del mismo tono y, con [showIcon], un ícono
/// propio de cada tono. El estado nunca depende solo del color: el texto lo
/// dice y el ícono lo refuerza.
class QaStatusChip extends StatelessWidget {
  const QaStatusChip({
    required this.tone,
    required this.label,
    this.showIcon = true,
    super.key,
  });

  final QaTone tone;
  final String label;

  /// Muestra el ícono del tono antes del texto.
  final bool showIcon;

  /// El ícono de cada tono.
  static IconData iconOf(QaTone tone) => switch (tone) {
    QaTone.free => Icons.check_circle_outline_rounded,
    QaTone.limited => Icons.info_outline_rounded,
    QaTone.full => Icons.error_outline_rounded,
    QaTone.occupied => Icons.directions_car_outlined,
    QaTone.unknown => Icons.help_outline_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.qaColors;
    final foreground = colors.onFill(tone);
    return Semantics(
      container: true,
      label: label,
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: colors.fill(tone),
            shape: const StadiumBorder(),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: QaSpacing.md,
              vertical: QaSpacing.xs + 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showIcon) ...[
                  Icon(iconOf(tone), size: 16, color: foreground),
                  const SizedBox(width: QaSpacing.xs + 2),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: foreground),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

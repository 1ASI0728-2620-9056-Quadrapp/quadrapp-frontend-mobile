import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_colors.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_spacing.dart';

/// Antigüedad de un dato ("hace 40 s"). El texto ya viene formateado y
/// traducido; el componente solo lo presenta. Si [isStale], se resalta con el
/// tono "limitada", un ícono de aviso y texto en negrita (no solo color).
class QaFreshnessLabel extends StatelessWidget {
  const QaFreshnessLabel({
    required this.label,
    this.isStale = false,
    super.key,
  });

  final String label;
  final bool isStale;

  @override
  Widget build(BuildContext context) {
    final colors = context.qaColors;
    final theme = Theme.of(context);
    final color = isStale ? colors.limitedText : colors.onSurfaceMuted;
    return Semantics(
      container: true,
      label: label,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                isStale ? Icons.warning_amber_rounded : Icons.schedule,
                size: 16,
                color: color,
              ),
            ),
            const SizedBox(width: QaSpacing.xs),
            Flexible(
              child: Text(
                label,
                style:
                    (isStale
                            ? theme.textTheme.labelMedium
                            : theme.textTheme.bodyMedium)
                        ?.copyWith(color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

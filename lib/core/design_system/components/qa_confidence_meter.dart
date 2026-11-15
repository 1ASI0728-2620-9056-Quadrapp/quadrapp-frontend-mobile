import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/core/design_system/components/qa_tone_glyph.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_colors.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_spacing.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_tone.dart';

/// Nivel de confianza mostrado por [QaConfidenceMeter].
enum QaConfidenceLevel { low, medium, high }

/// Medidor de confianza: 3 segmentos más el texto ([label]). La confianza baja
/// no se esconde: se resalta con el tono "limitada" y una nota ([note]) como
/// "Estimación con pocos datos".
class QaConfidenceMeter extends StatelessWidget {
  const QaConfidenceMeter({
    required this.level,
    required this.label,
    this.note,
    super.key,
  });

  final QaConfidenceLevel level;

  /// Texto del nivel, por ejemplo "Confianza media".
  final String label;

  /// Aviso adicional (obligatorio en la práctica cuando [level] es `low`).
  final String? note;

  @override
  Widget build(BuildContext context) {
    final colors = context.qaColors;
    final theme = Theme.of(context);
    final isLow = level == QaConfidenceLevel.low;
    final segmentColor = isLow ? colors.limitedText : colors.primary;
    final filled = switch (level) {
      QaConfidenceLevel.low => 1,
      QaConfidenceLevel.medium => 2,
      QaConfidenceLevel.high => 3,
    };

    return Semantics(
      container: true,
      label: note == null ? label : '$label. $note',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: QaSpacing.sm,
              runSpacing: QaSpacing.xs,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < 3; i++) ...[
                      if (i > 0) const SizedBox(width: QaSpacing.xs),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: i < filled ? segmentColor : colors.surface,
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(color: segmentColor, width: 1.5),
                        ),
                        child: const SizedBox(width: 24, height: 8),
                      ),
                    ],
                  ],
                ),
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
            if (note != null) ...[
              const SizedBox(height: QaSpacing.xs),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isLow) ...[
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: QaToneGlyph(tone: QaTone.limited, size: 12),
                    ),
                    const SizedBox(width: QaSpacing.sm),
                  ],
                  Expanded(
                    child: Text(
                      note!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isLow
                            ? colors.limitedText
                            : colors.onSurfaceMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

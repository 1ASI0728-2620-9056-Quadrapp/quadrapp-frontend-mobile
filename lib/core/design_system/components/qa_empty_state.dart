import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/core/design_system/components/qa_button.dart';
import 'package:quadrapp_mobile/core/design_system/components/qa_illustration.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_colors.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_spacing.dart';

/// Estado vacío: explica qué falta e invita a actuar con una acción.
class QaEmptyState extends StatelessWidget {
  const QaEmptyState({
    required this.title,
    this.icon,
    this.illustration,
    this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
    super.key,
  });

  /// Un ícono sencillo (para estados compactos). Si hay [illustration], gana
  /// la ilustración.
  final IconData? icon;

  /// La ilustración propia del estado vacío (recomendada: cada estado vacío
  /// lleva una).
  final QaIllustrationKind? illustration;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Versión para insertar dentro de otra superficie (menos relleno).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.qaColors;
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.all(compact ? QaSpacing.lg : QaSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (illustration != null)
            QaIllustration(kind: illustration!)
          else if (icon != null)
            ExcludeSemantics(
              child: Icon(icon, size: 40, color: colors.onSurfaceMuted),
            ),
          const SizedBox(height: QaSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          if (message != null) ...[
            const SizedBox(height: QaSpacing.sm),
            Text(
              message!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceMuted,
              ),
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: QaSpacing.lg),
            QaButton(
              label: actionLabel!,
              onPressed: onAction,
              variant: QaButtonVariant.tonal,
            ),
          ],
        ],
      ),
    );
  }
}

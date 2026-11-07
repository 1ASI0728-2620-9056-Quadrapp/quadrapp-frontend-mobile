import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/core/design_system/components/qa_button.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_colors.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_spacing.dart';

/// Estado vacío de una función que todavía no existe: ícono grande en un
/// círculo tonal, un título, una línea honesta sobre lo que habrá y, si
/// procede, una vista previa ([preview]) y una acción.
///
/// A diferencia de `QaEmptyState` (algo que falta y se puede resolver), este
/// dice que la función llega en una próxima actualización; no promete fechas.
class QaComingSoon extends StatelessWidget {
  const QaComingSoon({
    required this.icon,
    required this.title,
    required this.message,
    this.preview,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final IconData icon;
  final String title;

  /// Una línea honesta sobre lo que habrá.
  final String message;

  /// Una vista previa de lo que habrá (decorativa: debe llevar su propia
  /// etiqueta de "ejemplo").
  final Widget? preview;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Diámetro del círculo tonal del ícono.
  static const double badgeSize = 96;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.qaColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: ExcludeSemantics(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: SizedBox.square(
                dimension: badgeSize,
                child: Icon(icon, size: 48, color: colors.onPrimaryContainer),
              ),
            ),
          ),
        ),
        const SizedBox(height: QaSpacing.xl),
        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: QaSpacing.sm),
        Text(
          message,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colors.onSurfaceMuted,
          ),
        ),
        if (preview != null) ...[
          const SizedBox(height: QaSpacing.xl),
          preview!,
        ],
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: QaSpacing.xl),
          QaButton(
            label: actionLabel!,
            variant: QaButtonVariant.tonal,
            size: QaButtonSize.large,
            expand: true,
            onPressed: onAction,
          ),
        ],
      ],
    );
  }
}

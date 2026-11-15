import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/core/design_system/components/qa_button.dart';
import 'package:quadrapp_mobile/core/design_system/components/qa_illustration.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_colors.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_spacing.dart';

/// Error recuperable: dice la causa y ofrece una salida ([retryLabel]).
/// Se anuncia como región viva.
class QaErrorState extends StatelessWidget {
  const QaErrorState({
    required this.title,
    required this.message,
    required this.retryLabel,
    required this.onRetry,
    this.illustration,
    this.compact = false,
    super.key,
  });

  final String title;

  /// La causa del error, en lenguaje claro.
  final String message;
  final String retryLabel;
  final VoidCallback? onRetry;

  /// La ilustración del error (por ejemplo, un sensor sin señal); sin ella,
  /// un ícono de error.
  final QaIllustrationKind? illustration;

  /// Versión para insertar dentro de otra superficie (menos relleno).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = context.qaColors;
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: EdgeInsets.all(compact ? QaSpacing.lg : QaSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (illustration != null)
              QaIllustration(kind: illustration!)
            else
              ExcludeSemantics(
                child: Icon(Icons.error_outline, size: 40, color: colors.full),
              ),
            const SizedBox(height: QaSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: QaSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: QaSpacing.lg),
            QaButton(label: retryLabel, onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

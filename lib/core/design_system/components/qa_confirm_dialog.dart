import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/core/design_system/components/qa_button.dart';
import 'package:quadrapp_mobile/core/design_system/components/qa_haptics.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_colors.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_radii.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_spacing.dart';

/// Diálogo de confirmación que **nombra el objeto afectado** ([subject]: la
/// cuenta, la franja, el dispositivo), en un recuadro aparte para que no se
/// pueda confirmar sin saber sobre qué.
///
/// Con [destructive] el botón de confirmar va en Alert (coral oscuro) y el foco
/// empieza en "cancelar" (lo seguro). Confirmar da una háptica ligera. Los
/// botones se apilan si el texto no cabe.
class QaConfirmDialog extends StatelessWidget {
  const QaConfirmDialog({
    required this.title,
    required this.subject,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    this.icon,
    this.destructive = false,
    super.key,
  }) : assert(subject != '', 'El diálogo debe nombrar el objeto afectado');

  final String title;

  /// El nombre del objeto afectado.
  final String subject;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final IconData? icon;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = context.qaColors;
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              container: true,
              label: subject,
              child: ExcludeSemantics(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surfaceMuted,
                    borderRadius: QaRadii.controlRadius,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(QaSpacing.md),
                    child: Row(
                      children: [
                        if (icon != null) ...[
                          Icon(icon, color: colors.onSurface),
                          const SizedBox(width: QaSpacing.md),
                        ],
                        Expanded(
                          child: Text(
                            subject,
                            style: theme.textTheme.titleSmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: QaSpacing.lg),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colors.onSurface,
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        QaSpacing.lg,
        0,
        QaSpacing.lg,
        QaSpacing.lg,
      ),
      actionsOverflowDirection: VerticalDirection.down,
      actionsOverflowButtonSpacing: QaSpacing.sm,
      actions: [
        Focus(
          autofocus: destructive,
          child: QaButton(
            label: cancelLabel,
            variant: QaButtonVariant.text,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ),
        QaButton(
          label: confirmLabel,
          variant: destructive
              ? QaButtonVariant.destructive
              : QaButtonVariant.primary,
          onPressed: () {
            QaHaptics.confirm();
            Navigator.of(context).pop(true);
          },
        ),
      ],
    );
  }
}

/// Muestra un [QaConfirmDialog] y devuelve `true` si se confirma. Cancelar o
/// cerrar el diálogo devuelve `false`.
Future<bool> showQaConfirmDialog(
  BuildContext context, {
  required String title,
  required String subject,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  IconData? icon,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => QaConfirmDialog(
      title: title,
      subject: subject,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      icon: icon,
      destructive: destructive,
    ),
  );
  return result ?? false;
}

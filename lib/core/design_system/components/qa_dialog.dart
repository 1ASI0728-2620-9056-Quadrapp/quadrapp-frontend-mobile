import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/core/design_system/components/qa_button.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_colors.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_spacing.dart';

/// Diálogo de confirmación. Para acciones destructivas (cerrar sesión, dar de
/// baja una suscripción) el [message] debe nombrar el objeto afectado.
class QaDialog extends StatelessWidget {
  const QaDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.cancelLabel,
    this.destructive = false,
    super.key,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final colors = context.qaColors;
    return AlertDialog(
      title: Text(title),
      content: SingleChildScrollView(
        child: Text(
          message,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: colors.onSurface),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        QaSpacing.lg,
        0,
        QaSpacing.lg,
        QaSpacing.lg,
      ),
      actions: [
        QaButton(
          label: cancelLabel,
          variant: QaButtonVariant.text,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        QaButton(
          label: confirmLabel,
          variant: destructive
              ? QaButtonVariant.destructive
              : QaButtonVariant.primary,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}

/// Muestra un [QaDialog] y devuelve `true` si el usuario confirma. Cancelar o
/// cerrar el diálogo devuelve `false`.
Future<bool> showQaDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => QaDialog(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      destructive: destructive,
    ),
  );
  return result ?? false;
}

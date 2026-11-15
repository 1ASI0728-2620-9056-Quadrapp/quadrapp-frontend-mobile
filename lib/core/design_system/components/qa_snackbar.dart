import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_spacing.dart';

/// Aviso breve de una acción hecha ("Alert saved"), con **"Undo"** cuando la
/// acción se puede deshacer. Dura [duration] (6 s por defecto, para que haya
/// tiempo de leerlo y tocar "Undo"), se anuncia como región viva y reemplaza
/// al aviso anterior. Sale sobre la barra inferior de la pantalla actual.
void showQaSnackbar(
  BuildContext context, {
  required String message,
  IconData? icon = Icons.check_circle_outline,
  String? undoLabel,
  VoidCallback? onUndo,
  Duration duration = const Duration(seconds: 6),
}) {
  final messenger = ScaffoldMessenger.of(context);
  final textStyle = Theme.of(context).snackBarTheme.contentTextStyle;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        persist: false,
        duration: duration,
        content: Semantics(
          liveRegion: true,
          child: Row(
            children: [
              if (icon != null) ...[
                ExcludeSemantics(
                  child: Icon(icon, size: 20, color: textStyle?.color),
                ),
                const SizedBox(width: QaSpacing.md),
              ],
              Expanded(child: Text(message)),
            ],
          ),
        ),
        action: undoLabel != null && onUndo != null
            ? SnackBarAction(label: undoLabel, onPressed: onUndo)
            : null,
      ),
    );
}

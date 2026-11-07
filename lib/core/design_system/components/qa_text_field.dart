import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_colors.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_spacing.dart';

/// Campo de texto del diseño: la etiqueta en negrita **encima** del campo, el
/// campo de 52 dp con borde fino (2 dp con foco) y el texto de ayuda debajo.
/// Valida al salir del campo (`AutovalidateMode.onUnfocus`) y muestra el error
/// con ícono y texto, no solo con color. Un [errorText] externo (por ejemplo,
/// un error del servidor) tiene prioridad sobre el [validator].
///
/// La etiqueta y el campo se anuncian juntos (un solo nodo semántico).
class QaTextField extends StatelessWidget {
  const QaTextField({
    required this.label,
    this.controller,
    this.focusNode,
    this.hint,
    this.helperText,
    this.errorText,
    this.prefixIcon,
    this.validator,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.inputFormatters,
    this.obscureText = false,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hint;
  final String? helperText;
  final String? errorText;

  /// Ícono al inicio del campo (decorativo: la etiqueta ya dice qué es).
  final IconData? prefixIcon;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.qaColors;

    Widget errorWidget(String message) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.error_outline, size: 16, color: colors.full),
          ),
        ),
        const SizedBox(width: QaSpacing.sm),
        Expanded(
          child: Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(color: colors.full),
          ),
        ),
      ],
    );

    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: enabled ? colors.onSurface : colors.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: QaSpacing.sm),
          TextFormField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            autofillHints: autofillHints,
            inputFormatters: inputFormatters,
            autovalidateMode: AutovalidateMode.onUnfocus,
            validator: validator,
            forceErrorText: errorText,
            errorBuilder: (context, message) => errorWidget(message),
            onChanged: onChanged,
            onFieldSubmitted: onSubmitted,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurface,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceMuted,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: QaSpacing.lg,
                vertical: QaSpacing.md,
              ),
              prefixIcon: prefixIcon == null
                  ? null
                  : ExcludeSemantics(child: Icon(prefixIcon, size: 24)),
            ),
          ),
          if (helperText != null && errorText == null)
            Padding(
              padding: const EdgeInsets.only(top: QaSpacing.sm),
              child: Text(
                helperText!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceMuted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

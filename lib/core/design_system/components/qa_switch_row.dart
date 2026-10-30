import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_colors.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_radii.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_spacing.dart';

/// Una fila de interruptor (las de «Avísame cuando» y las del ETA): ícono, el
/// título en negrita, una línea de ayuda y el interruptor. Toda la fila se
/// puede tocar. Sin [onChanged] está desactivada. Se anuncia como un solo
/// control con su estado (el título y la ayuda son su etiqueta).
class QaSwitchRow extends StatelessWidget {
  const QaSwitchRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.help,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? help;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.qaColors;
    final enabled = onChanged != null;
    final help = this.help;
    return MergeSemantics(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: enabled ? () => onChanged!(!value) : null,
          borderRadius: QaRadii.controlRadius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 64),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: QaSpacing.sm),
              child: Row(
                children: [
                  ExcludeSemantics(
                    child: Icon(
                      icon,
                      color: enabled ? colors.primary : colors.onSurfaceMuted,
                    ),
                  ),
                  const SizedBox(width: QaSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (help != null)
                          Text(
                            help,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceMuted,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: QaSpacing.sm),
                  Switch(value: value, onChanged: onChanged),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

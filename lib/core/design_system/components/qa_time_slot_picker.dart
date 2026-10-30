import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_colors.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_radii.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_spacing.dart';

/// Selector de franja horaria: días de la semana (1 = lunes ... 7 = domingo)
/// y hora de inicio y fin. No guarda estado: todo entra por parámetros y los
/// cambios salen por callbacks. Los textos ya vienen traducidos.
class QaTimeSlotPicker extends StatelessWidget {
  const QaTimeSlotPicker({
    required this.dayLabels,
    required this.dayNames,
    required this.selectedDays,
    required this.from,
    required this.to,
    required this.daysLabel,
    required this.fromLabel,
    required this.toLabel,
    required this.pickTimeLabel,
    required this.onDaysChanged,
    required this.onFromChanged,
    required this.onToChanged,
    this.errorText,
    this.enabled = true,
    super.key,
  }) : assert(dayLabels.length == 7, 'Se necesitan 7 rótulos de día.'),
       assert(dayNames.length == 7, 'Se necesitan 7 nombres de día.');

  /// Rótulos cortos, de lunes a domingo.
  final List<String> dayLabels;

  /// Nombres completos para lectores de pantalla, de lunes a domingo.
  final List<String> dayNames;
  final Set<int> selectedDays;
  final TimeOfDay? from;
  final TimeOfDay? to;
  final String daysLabel;
  final String fromLabel;
  final String toLabel;

  /// Texto cuando aún no hay hora elegida.
  final String pickTimeLabel;
  final ValueChanged<Set<int>> onDaysChanged;
  final ValueChanged<TimeOfDay> onFromChanged;
  final ValueChanged<TimeOfDay> onToChanged;
  final String? errorText;
  final bool enabled;

  Future<void> _pick(
    BuildContext context,
    TimeOfDay? current,
    ValueChanged<TimeOfDay> onChanged,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: current ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.qaColors;
    final theme = Theme.of(context);
    final localizations = MaterialLocalizations.of(context);

    final labelStyle = theme.textTheme.labelMedium?.copyWith(
      color: colors.onSurface,
    );
    final invalid = errorText != null;

    // Hora como un campo de formulario: rótulo arriba, valor y reloj dentro.
    Widget timeField(
      String label,
      TimeOfDay? value,
      ValueChanged<TimeOfDay> onChanged,
    ) {
      final text = value == null
          ? pickTimeLabel
          : localizations.formatTimeOfDay(value);
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ExcludeSemantics(child: Text(label, style: labelStyle)),
            const SizedBox(height: QaSpacing.sm),
            Semantics(
              button: true,
              enabled: enabled,
              label: '$label, $text',
              excludeSemantics: true,
              child: Material(
                color: colors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: QaRadii.controlRadius,
                  side: BorderSide(
                    color: invalid ? colors.full : colors.outline,
                    width: invalid ? 2 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: enabled
                      ? () => _pick(context, value, onChanged)
                      : null,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 52),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: QaSpacing.md,
                        vertical: QaSpacing.sm,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              text,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: value == null
                                    ? colors.onSurfaceMuted
                                    : colors.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: QaSpacing.sm),
                          Icon(
                            Icons.schedule_rounded,
                            size: 20,
                            color: colors.onSurfaceMuted,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Un día: casilla; elegida va rellena de teal (no solo cambia el
    // color: cambia de contorno a relleno).
    Widget dayTile(int i, double size) {
      final day = i + 1;
      final selected = selectedDays.contains(day);
      return Semantics(
        label: dayNames[i],
        selected: selected,
        button: true,
        enabled: enabled,
        excludeSemantics: true,
        child: SizedBox(
          width: size,
          // Nunca por debajo del objetivo táctil mínimo.
          height: size < QaSpacing.minTapTarget ? QaSpacing.minTapTarget : size,
          child: Material(
            color: selected ? colors.primary : colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: QaRadii.controlRadius,
              side: BorderSide(
                color: selected ? colors.primary : colors.outline,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: enabled
                  ? () {
                      final next = {...selectedDays};
                      if (selected) {
                        next.remove(day);
                      } else {
                        next.add(day);
                      }
                      onDaysChanged(next);
                    }
                  : null,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(QaSpacing.xs),
                  child: Text(
                    dayLabels[i],
                    maxLines: 1,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: selected ? colors.onPrimary : colors.onSurface,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(daysLabel, style: labelStyle),
        const SizedBox(height: QaSpacing.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            const gap = 6.0;
            // Siete casillas en una fila; con el texto grande, cada una crece
            // y la fila pasa a dos líneas.
            final fit = (constraints.maxWidth - gap * 6) / 7;
            final needed = MediaQuery.textScalerOf(context).scale(34);
            final size = fit >= needed
                ? fit
                : needed.clamp(QaSpacing.minTapTarget, constraints.maxWidth);
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [for (var i = 0; i < 7; i++) dayTile(i, size)],
            );
          },
        ),
        const SizedBox(height: QaSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            timeField(fromLabel, from, onFromChanged),
            const SizedBox(width: QaSpacing.md),
            timeField(toLabel, to, onToChanged),
          ],
        ),
        if (errorText != null) ...[
          const SizedBox(height: QaSpacing.sm),
          Semantics(
            liveRegion: true,
            child: Text(
              errorText!,
              style: theme.textTheme.bodyMedium?.copyWith(color: colors.full),
            ),
          ),
        ],
      ],
    );
  }
}

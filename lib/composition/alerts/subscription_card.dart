// US33
import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/composition/alerts/alert_format.dart';
import 'package:quadrapp_mobile/contexts/notifications/notifications.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';

/// Una fila de «Tus franjas» (va dentro de la tarjeta de la lista, separada
/// por divisores, como «Avísame cuando»): la sede, los días y la hora, con su
/// interruptor (pausarla la conserva, US33 esc. 3) y el botón de eliminarla
/// (la baja definitiva, con confirmación). Una franja pausada lo dice con una
/// etiqueta y se ve atenuada: nunca solo con el color.
///
/// Con el texto grande, el interruptor y el botón pasan debajo del texto.
class SubscriptionCard extends StatelessWidget {
  const SubscriptionCard({
    required this.subscription,
    required this.lotName,
    required this.onActiveChanged,
    required this.onDelete,
    super.key,
  });

  final AlertSubscription subscription;
  final String lotName;
  final ValueChanged<bool> onActiveChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;
    final locale = Localizations.localeOf(context).languageCode;
    final stacked = MediaQuery.textScalerOf(context).scale(16) >= 22;
    final active = subscription.active;
    final days = daysLabel(subscription.days, locale);
    final time = slotLabel(subscription.slot, locale);

    final detailStyle = theme.textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceMuted,
    );

    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          lotName,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: active ? null : colors.onSurfaceMuted,
          ),
        ),
        const SizedBox(height: QaSpacing.xs),
        // Los días y el rango van por separado: si no caben juntos, el rango
        // pasa entero a la línea siguiente.
        Wrap(
          spacing: QaSpacing.xs,
          children: [
            Text('$days ·', style: detailStyle),
            Text(time, style: detailStyle),
          ],
        ),
        if (!active) ...[
          const SizedBox(height: QaSpacing.xs),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.pause_circle_outline_rounded,
                size: 14,
                color: colors.accent(QaTone.unknown),
              ),
              const SizedBox(width: QaSpacing.xs),
              Text(
                l10n.alerts_slotPaused,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.accent(QaTone.unknown),
                ),
              ),
            ],
          ),
        ],
      ],
    );

    final actions = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          container: true,
          label: l10n.alerts_slotSwitchLabel(lotName, days, time),
          child: Switch(value: active, onChanged: onActiveChanged),
        ),
        IconButton(
          tooltip: l10n.alerts_slotDeleteTooltip(lotName, days, time),
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline_rounded),
          color: colors.onSurfaceMuted,
          constraints: const BoxConstraints.tightFor(
            width: QaSpacing.minTapTarget,
            height: QaSpacing.minTapTarget,
          ),
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: QaSpacing.md),
      child: stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                details,
                const SizedBox(height: QaSpacing.sm),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: actions,
                ),
              ],
            )
          : Row(
              children: [
                ExcludeSemantics(
                  child: Icon(
                    Icons.schedule_rounded,
                    color: active ? colors.primary : colors.onSurfaceMuted,
                  ),
                ),
                const SizedBox(width: QaSpacing.md),
                Expanded(child: details),
                actions,
              ],
            ),
    );
  }
}

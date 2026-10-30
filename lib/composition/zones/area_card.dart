// US06, US08
import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/composition/zones/zones_copy.dart';
import 'package:quadrapp_mobile/composition/zones/zones_state.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';

/// La tarjeta de un pabellón o de un nivel: nombre, qué cubre, la píldora de
/// disponibilidad («Buena», «Limitada»…), los libres en grande, los sin datos
/// aparte (en ámbar cuando los hay) y la flecha de que abre algo. Toda la
/// tarjeta es un solo objetivo táctil.
///
/// Sin conteo ([counts] nulo) se ve «—» con la píldora «Sin datos». Los sin
/// datos nunca se suman a los libres (US06 esc. 3).
class AreaCard extends StatelessWidget {
  const AreaCard({
    required this.title,
    required this.counts,
    required this.saturationThresholdPct,
    required this.hint,
    required this.onTap,
    this.subtitle,
    super.key,
  });

  final String title;

  /// Qué cubre el pabellón («Edificios A–C»); puede faltar.
  final String? subtitle;
  final AreaCounts? counts;
  final int saturationThresholdPct;

  /// Qué abre la tarjeta (para TalkBack).
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;
    final counts = this.counts;
    final subtitle = this.subtitle;
    final availability =
        counts?.availability(saturationThresholdPct) ??
        SpaceAvailability.noData;
    final tone = toneOfAvailability(availability);
    final unknown = counts?.unknown ?? 0;

    final freeColor = counts == null
        ? colors.onSurfaceMuted
        : counts.free == 0
        ? colors.accent(QaTone.full)
        : colors.accent(QaTone.free);

    final stacked = MediaQuery.textScalerOf(context).scale(16) >= 22;
    final freeText = Text(
      counts == null ? '—' : l10n.zones_freeCount(counts.free),
      style: theme.textTheme.headlineSmall?.copyWith(color: freeColor),
    );
    final unknownText = counts == null
        ? null
        : Text(
            l10n.zones_unknownCount(unknown),
            style: theme.textTheme.labelMedium?.copyWith(
              color: unknown > 0
                  ? colors.accent(QaTone.unknown)
                  : colors.onSurfaceMuted,
            ),
          );

    final spoken = l10n.zones_zoneSemantics(
      title,
      subtitle == null ? '' : ', $subtitle',
      counts == null ? '—' : l10n.zones_freeCount(counts.free),
      counts == null ? '—' : l10n.zones_unknownCount(unknown),
      availabilityLabel(l10n, availability),
    );

    return QaCard(
      onTap: onTap,
      semanticLabel: spoken,
      semanticHint: hint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceMuted,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: QaSpacing.md),
              QaStatusChip(
                tone: tone,
                label: availabilityLabel(l10n, availability),
              ),
            ],
          ),
          const SizedBox(height: QaSpacing.md),
          Row(
            children: [
              Expanded(
                child: stacked
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [freeText, ?unknownText],
                      )
                    : Row(
                        children: [
                          Expanded(flex: 5, child: freeText),
                          if (unknownText != null)
                            Expanded(flex: 4, child: unknownText),
                        ],
                      ),
              ),
              Icon(
                Directionality.of(context) == TextDirection.rtl
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                color: colors.onSurfaceMuted,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

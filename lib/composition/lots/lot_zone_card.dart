// US06, US08 (vista del administrador de universidad)
import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/composition/zones/zones_copy.dart';
import 'package:quadrapp_mobile/composition/zones/zones_state.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';

/// Una zona en Estacionamientos: su nombre, el % ocupado (sin los
/// desconocidos, en el tono de su disponibilidad), sus cifras y su estado:
/// «Operativa» o «Atención» si tiene espacios desconocidos. Tocarla la elige
/// y muestra sus espacios abajo; la elegida lleva el borde de marca.
class LotZoneCard extends StatelessWidget {
  const LotZoneCard({
    required this.zone,
    required this.counts,
    required this.saturationThresholdPct,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final Zone zone;

  /// `null` si aún no hay ocupación.
  final AreaCounts? counts;
  final int saturationThresholdPct;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;
    final counts = this.counts;

    // Ocupación sin los desconocidos, que no son libres ni ocupados.
    final counted = counts == null ? 0 : counts.free + counts.occupied;
    final fraction = counts == null || counted == 0
        ? null
        : counts.occupied / counted;
    final availability = counts?.availability(saturationThresholdPct);
    final pctText = fraction == null
        ? l10n.lots_zoneNoData
        : l10n.lots_zoneOccupied((fraction * 100).round());
    final pctColor = availability == null
        ? colors.onSurfaceMuted
        : colors.accent(toneOfAvailability(availability));

    final countsText = counts == null
        ? null
        : l10n.lots_zoneCounts(
            counts.total,
            counts.free,
            counts.occupied,
            counts.unknown,
          );
    final attention = (counts?.unknown ?? 0) > 0;
    final statusText = counts == null
        ? null
        : attention
        ? l10n.lots_zoneAttention(counts.unknown)
        : l10n.lots_zoneOk;
    final statusColor = attention
        ? colors.accent(QaTone.limited)
        : colors.accent(QaTone.free);

    return Semantics(
      selected: selected,
      child: QaCard(
        onTap: onTap,
        borderColor: selected ? colors.primary : null,
        semanticLabel: [
          zone.name,
          pctText,
          ?countsText,
          ?statusText,
        ].join('. '),
        semanticHint: l10n.lots_zoneHint,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(zone.name, style: theme.textTheme.titleMedium),
                ),
                const SizedBox(width: QaSpacing.sm),
                Text(
                  pctText,
                  style: theme.textTheme.labelLarge?.copyWith(color: pctColor),
                ),
              ],
            ),
            if (countsText != null) ...[
              const SizedBox(height: QaSpacing.xs),
              Text(
                countsText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceMuted,
                ),
              ),
            ],
            if (statusText != null) ...[
              const SizedBox(height: QaSpacing.sm),
              Row(
                children: [
                  Icon(
                    attention
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 18,
                    color: statusColor,
                  ),
                  const SizedBox(width: QaSpacing.xs + 2),
                  Flexible(
                    child: Text(
                      statusText,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

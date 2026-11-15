// US06, US08
import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/composition/zones/zones_state.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';

/// El resumen de una sede, un pabellón o un nivel: capacidad, libres y sin
/// datos (en ámbar cuando los hay). Los sin datos nunca suman a los libres.
/// Sin conteo ([counts] nulo) se ve «—».
///
/// Con el texto grande las tres cifras pasan de una fila a una columna.
class AreaSummaryCard extends StatelessWidget {
  const AreaSummaryCard({required this.counts, super.key});

  final AreaCounts? counts;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.qaColors;
    final counts = this.counts;
    final stacked = MediaQuery.textScalerOf(context).scale(16) >= 22;

    String number(int? value) => value == null ? '—' : '$value';
    final stats = [
      _Stat(
        label: l10n.zones_capacity,
        value: number(counts?.total),
        color: colors.onSurface,
      ),
      _Stat(
        label: l10n.zones_free,
        value: number(counts?.free),
        color: colors.accent(QaTone.free),
      ),
      _Stat(
        label: l10n.zones_unknown,
        value: number(counts?.unknown),
        color: (counts?.unknown ?? 0) > 0
            ? colors.accent(QaTone.unknown)
            : colors.onSurfaceMuted,
      ),
    ];

    final spoken = counts == null
        ? '${l10n.zones_capacity}, ${l10n.zones_free}, ${l10n.zones_unknown}: —'
        : [
            '${l10n.zones_capacity} ${counts.total}',
            l10n.zones_freeCount(counts.free),
            l10n.zones_unknownCount(counts.unknown),
          ].join(', ');

    return Semantics(
      container: true,
      label: spoken,
      excludeSemantics: true,
      child: QaCard(
        child: stacked
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < stats.length; i++) ...[
                    if (i > 0) const SizedBox(height: QaSpacing.md),
                    stats[i],
                  ],
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [for (final stat in stats) Expanded(child: stat)],
              ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.qaColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.onSurfaceMuted,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: QaSpacing.xs),
        Text(
          value,
          style: theme.textTheme.displaySmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

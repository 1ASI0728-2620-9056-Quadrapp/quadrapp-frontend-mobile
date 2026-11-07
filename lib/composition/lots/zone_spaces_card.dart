// US06, US08 (vista del administrador de universidad)
import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/composition/zones/zones_copy.dart';
import 'package:quadrapp_mobile/composition/zones/zones_state.dart';
import 'package:quadrapp_mobile/contexts/occupancy/occupancy.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';

/// Los espacios de la zona elegida: un filtro por estado y una grilla con los
/// primeros [maxTiles]. «Ver los N» abre la zona con todos sus espacios (mapa
/// y lista). Un espacio desconocido se ve con su rayado, su ícono y su texto,
/// nunca como libre.
class ZoneSpacesCard extends StatelessWidget {
  const ZoneSpacesCard({
    required this.zone,
    required this.spaces,
    required this.filter,
    required this.onFilter,
    required this.onSeeAll,
    super.key,
  });

  static const int maxTiles = 9;

  final Zone zone;
  final List<LevelSpace> spaces;

  /// `null` = todos.
  final SpaceStatus? filter;
  final ValueChanged<SpaceStatus?> onFilter;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;
    final shown = [
      for (final space in spaces)
        if (filter == null || space.status == filter) space,
    ];
    final hidden = shown.length - maxTiles;

    final options = <(SpaceStatus?, String)>[
      (null, l10n.lots_spacesAll),
      (SpaceStatus.free, l10n.shift_free),
      (SpaceStatus.occupied, l10n.shift_occupied),
      (SpaceStatus.unknown, l10n.shift_unknown),
    ];

    return QaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    l10n.lots_spacesTitle(zone.name),
                    style: theme.textTheme.titleMedium,
                  ),
                ),
              ),
              TextButton(
                onPressed: onSeeAll,
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, QaSpacing.minTapTarget),
                ),
                child: Text(l10n.lots_spacesSeeAll(spaces.length)),
              ),
            ],
          ),
          Wrap(
            spacing: QaSpacing.sm,
            runSpacing: QaSpacing.xs,
            children: [
              for (final (status, label) in options)
                ChoiceChip(
                  label: Text(label),
                  selected: filter == status,
                  showCheckmark: false,
                  onSelected: (_) => onFilter(status),
                ),
            ],
          ),
          const SizedBox(height: QaSpacing.md),
          if (shown.isEmpty)
            Text(
              l10n.lots_spacesEmpty,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceMuted,
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                const gap = QaSpacing.sm;
                final large = MediaQuery.textScalerOf(context).scale(16) >= 22;
                final perRow = large ? 2 : 3;
                final width =
                    (constraints.maxWidth - gap * (perRow - 1)) / perRow;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    for (final space in shown.take(maxTiles))
                      SizedBox(
                        width: width,
                        child: _SpaceTile(space: space),
                      ),
                  ],
                );
              },
            ),
          if (hidden > 0) ...[
            const SizedBox(height: QaSpacing.sm),
            Text(
              l10n.lots_spacesMore(hidden),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceMuted,
              ),
            ),
          ],
          const SizedBox(height: QaSpacing.md),
          Text(
            l10n.lots_spacesUnknownNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpaceTile extends StatelessWidget {
  const _SpaceTile({required this.space});

  final LevelSpace space;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;
    final tone = toneOfSpace(space.status);
    final state = space.status == SpaceStatus.unknown
        ? l10n.lots_spaceUnknown
        : spaceStatusLabel(l10n, space.status);
    return Semantics(
      label: '${space.label}, $state',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.fill(tone),
          borderRadius: QaRadii.controlRadius,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: QaSpacing.sm + 2,
            vertical: QaSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      space.label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                  QaToneGlyph(tone: tone, size: 10),
                ],
              ),
              const SizedBox(height: QaSpacing.xs),
              Text(
                state,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.accent(tone),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// US17
import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';

/// «Plano del estacionamiento»: una ficha por zona (se desplaza de lado) con
/// un mini plano de sus espacios, y debajo los espacios de la zona elegida
/// como chips de 48 dp para elegir uno (los cuadritos del mini plano son
/// demasiado pequeños para tocarlos). Lo nuevo lleva el tono de marca; lo
/// deshabilitado, tachado y con su ícono.
class LayoutPlanCard extends StatefulWidget {
  const LayoutPlanCard({
    required this.layout,
    required this.selectedZoneKey,
    required this.selectedSpaceKey,
    required this.onSelectZone,
    required this.onSelectSpace,
    super.key,
  });

  /// Cuántos chips se ven antes de «Mostrar los N».
  static const int collapsedChips = 24;

  final DraftLayout layout;
  final String? selectedZoneKey;
  final String? selectedSpaceKey;
  final ValueChanged<String> onSelectZone;
  final ValueChanged<String> onSelectSpace;

  @override
  State<LayoutPlanCard> createState() => _LayoutPlanCardState();
}

class _LayoutPlanCardState extends State<LayoutPlanCard> {
  bool _expanded = false;

  @override
  void didUpdateWidget(LayoutPlanCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedZoneKey != widget.selectedZoneKey) {
      _expanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;
    final zones = widget.layout.zones;
    final selected = widget.selectedZoneKey == null
        ? null
        : widget.layout.zone(widget.selectedZoneKey!);

    return QaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.layout_planTitle,
              style: theme.textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: QaSpacing.md),
          if (zones.isEmpty)
            Text(
              l10n.layout_planEmpty,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceMuted,
              ),
            )
          else ...[
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surfaceMuted,
                borderRadius: QaRadii.controlRadius,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.all(QaSpacing.sm),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final zone in zones) ...[
                        _ZoneTile(
                          zone: zone,
                          selected: zone.key == widget.selectedZoneKey,
                          selectedSpaceKey: widget.selectedSpaceKey,
                          onTap: () => widget.onSelectZone(zone.key),
                        ),
                        if (zone != zones.last)
                          const SizedBox(width: QaSpacing.sm),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: QaSpacing.sm),
            Text(
              l10n.layout_planHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceMuted,
              ),
            ),
            if (selected != null && selected.spaces.isNotEmpty) ...[
              const SizedBox(height: QaSpacing.lg),
              Text(
                l10n.layout_spacesOf(selected.name),
                style: theme.textTheme.labelLarge,
              ),
              const SizedBox(height: QaSpacing.sm),
              _spaceChips(context, l10n, selected),
            ],
          ],
        ],
      ),
    );
  }

  Widget _spaceChips(
    BuildContext context,
    AppLocalizations l10n,
    DraftZone zone,
  ) {
    final colors = context.qaColors;
    final spaces = zone.spaces;
    final visible = _expanded
        ? spaces
        : spaces.take(LayoutPlanCard.collapsedChips).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: QaSpacing.xs,
          runSpacing: QaSpacing.xs,
          children: [
            for (final space in visible)
              ChoiceChip(
                showCheckmark: false,
                selected: space.key == widget.selectedSpaceKey,
                avatar: space.enabled
                    ? (space.isNew
                          ? Icon(Icons.add_rounded, color: colors.primary)
                          : null)
                    : Icon(Icons.block_rounded, color: colors.full),
                label: Text(
                  space.label,
                  style: space.enabled
                      ? null
                      : const TextStyle(
                          decoration: TextDecoration.lineThrough,
                        ),
                ),
                onSelected: (_) => widget.onSelectSpace(space.key),
              ),
          ],
        ),
        if (!_expanded && spaces.length > LayoutPlanCard.collapsedChips)
          TextButton(
            onPressed: () => setState(() => _expanded = true),
            style: TextButton.styleFrom(
              minimumSize: const Size(0, QaSpacing.minTapTarget),
            ),
            child: Text(l10n.layout_showAll(spaces.length)),
          ),
      ],
    );
  }
}

/// Una zona en el plano: nombre, cuántos espacios cuentan y su mini plano.
class _ZoneTile extends StatelessWidget {
  const _ZoneTile({
    required this.zone,
    required this.selected,
    required this.selectedSpaceKey,
    required this.onTap,
  });

  static const int maxCells = 15;

  final DraftZone zone;
  final bool selected;
  final String? selectedSpaceKey;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;
    final spaces = zone.spaces;
    final count = zone.enabledCount;
    return Semantics(
      button: true,
      selected: selected,
      label: [
        zone.name,
        l10n.layout_zoneSpaces(count),
        if (zone.isNew) l10n.layout_zoneNew,
      ].join(', '),
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: selected ? colors.primaryContainer : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: QaRadii.controlRadius,
          side: BorderSide(
            color: selected ? colors.primary : colors.outline,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 136,
            child: Padding(
              padding: const EdgeInsets.all(QaSpacing.sm + 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          zone.name,
                          style: theme.textTheme.labelLarge,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (zone.isNew)
                        Icon(
                          Icons.fiber_new_outlined,
                          size: 18,
                          color: colors.primary,
                        ),
                    ],
                  ),
                  Text(
                    l10n.layout_zoneSpaces(count),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceMuted,
                    ),
                  ),
                  const SizedBox(height: QaSpacing.sm),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (final space in spaces.take(maxCells))
                        _Cell(
                          space: space,
                          selected: space.key == selectedSpaceKey,
                        ),
                    ],
                  ),
                  if (spaces.length > maxCells)
                    Padding(
                      padding: const EdgeInsets.only(top: QaSpacing.xs),
                      child: Text(
                        '+${spaces.length - maxCells}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceMuted,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.space, required this.selected});

  final DraftSpace space;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.qaColors;
    final Color fill;
    final Color border;
    if (selected) {
      fill = colors.primary;
      border = colors.primary;
    } else if (!space.enabled) {
      fill = colors.alertFill;
      border = colors.full;
    } else if (space.isNew) {
      fill = colors.primaryContainer;
      border = colors.primary;
    } else {
      fill = colors.surface;
      border = colors.outline;
    }
    return Container(
      width: 18,
      height: 12,
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: border),
      ),
    );
  }
}

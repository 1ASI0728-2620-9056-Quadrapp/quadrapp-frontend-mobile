// US06, US07, US08, TS09, TS13
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quadrapp_mobile/composition/zones/area_summary_card.dart';
import 'package:quadrapp_mobile/composition/zones/zones_copy.dart';
import 'package:quadrapp_mobile/composition/zones/zones_cubit.dart';
import 'package:quadrapp_mobile/composition/zones/zones_state.dart';
import 'package:quadrapp_mobile/composition/zones/zones_state_gate.dart';
import 'package:quadrapp_mobile/composition/zones/zones_sync.dart';
import 'package:quadrapp_mobile/contexts/occupancy/occupancy.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';
import 'package:quadrapp_mobile/core/time/countdown.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

enum _LevelView { map, list }

enum _SpaceFilter { all, free, unknown }

/// Nivel (`/zones/:zoneId/levels/:levelId`): el mapa de sus espacios en
/// tiempo real (libre: vacío con borde; ocupado: silueta de auto; sin datos:
/// rayado ámbar) y, como alternativa accesible, la lista de espacios con su
/// estado y, para los sin datos, el motivo (US08).
///
/// Si los espacios no tienen posición (no se puede dibujar el mapa), solo hay
/// lista y lo avisa. Un nivel que ya no existe en la distribución (cambió,
/// TS13) lo dice y ofrece volver.
class LevelPage extends StatefulWidget {
  const LevelPage({
    required this.zoneId,
    required this.levelId,
    required this.clock,
    required this.onBack,
    this.ticker,
    super.key,
  });

  final ZoneId zoneId;
  final LevelId levelId;
  final Clock clock;
  final VoidCallback onBack;
  final Ticker? ticker;

  @override
  State<LevelPage> createState() => _LevelPageState();
}

class _LevelPageState extends State<LevelPage> {
  _LevelView _view = _LevelView.map;
  _SpaceFilter _filter = _SpaceFilter.all;

  static Stream<void> _everySecond() =>
      Stream<void>.periodic(const Duration(seconds: 1));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ZonesSync(
      child: BlocBuilder<ZonesCubit, ViewState<ZonesOverview>>(
        builder: (context, state) {
          final overview = switch (state) {
            ViewData(:final data) => data,
            ViewPartial(:final data) => data,
            ViewLoading(:final previous) => previous,
            ViewError(:final previous) => previous,
            _ => null,
          };
          final level = overview?.levelById(widget.zoneId, widget.levelId);
          return QaTabPage(
            title: level?.name ?? l10n.title_zones,
            onBack: widget.onBack,
            backLabel: l10n.zones_backToZones,
            onRefresh: () => context.read<ZonesCubit>().refresh(),
            children: [
              ZonesStateGate(
                clock: widget.clock,
                ticker: widget.ticker ?? _everySecond,
                builder: _content,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _content(BuildContext context, ZonesOverview overview) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;

    // Sin distribución (parcial) no hay nivel que mostrar: el aviso de la
    // pantalla ya lo dice.
    if (overview.layout == null) return const SizedBox.shrink();
    final zone = overview.zoneById(widget.zoneId);
    final level = overview.levelById(widget.zoneId, widget.levelId);
    if (zone == null || level == null) {
      return QaEmptyState(
        illustration: QaIllustrationKind.parking,
        title: l10n.zones_levelNotFoundTitle,
        message: l10n.zones_notFoundMessage,
        actionLabel: l10n.zones_backToZones,
        onAction: widget.onBack,
        compact: true,
      );
    }

    final counts = overview.countsOfLevel(level.id);
    final spaces = overview.spacesOf(level);
    final canMap =
        spaces.isNotEmpty &&
        spaces.every((s) => s.posX != null && s.posY != null);
    final view = canMap ? _view : _LevelView.list;
    final stale = overview.occupancy?.freshness.isStale(widget.clock) ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          [zone.name, ?zone.description].join(' · '),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceMuted,
          ),
        ),
        const SizedBox(height: QaSpacing.md),
        AreaSummaryCard(counts: counts),
        if ((counts?.unknown ?? 0) > 0) ...[
          const SizedBox(height: QaSpacing.lg),
          QaBanner(
            kind: QaBannerKind.stale,
            icon: Icons.info_outline_rounded,
            message: l10n.zones_unknownBanner,
          ),
        ],
        const SizedBox(height: QaSpacing.lg),
        if (!canMap)
          QaBanner(kind: QaBannerKind.note, message: l10n.zones_noMap)
        else
          _ViewSwitch(
            view: view,
            onChanged: (value) => setState(() => _view = value),
          ),
        const SizedBox(height: QaSpacing.lg),
        if (view == _LevelView.map)
          _map(l10n, spaces, counts, stale: stale)
        else
          _list(context, spaces),
      ],
    );
  }

  Widget _map(
    AppLocalizations l10n,
    List<LevelSpace> spaces,
    AreaCounts? counts, {
    required bool stale,
  }) {
    final free = counts?.free ?? 0;
    final occupied = counts?.occupied ?? 0;
    final unknown = counts?.unknown ?? 0;
    return QaSpaceMap(
      cells: [
        for (final space in spaces)
          QaSpaceCell(
            id: space.id.value,
            x: space.posX!,
            y: space.posY!,
            state: switch (space.status) {
              SpaceStatus.free => QaSpaceState.free,
              SpaceStatus.occupied => QaSpaceState.occupied,
              SpaceStatus.unknown => QaSpaceState.unknown,
            },
          ),
      ],
      zones: const [],
      summaryLabel: l10n.zones_mapSummary(
        l10n.zones_freeCount(free),
        l10n.zones_occupiedCount(occupied),
        l10n.zones_unknownCount(unknown),
      ),
      legend: QaSpaceLegend(
        free: l10n.space_free,
        occupied: l10n.space_occupied,
        unknown: l10n.space_unknown,
      ),
      isStale: stale,
    );
  }

  Widget _list(BuildContext context, List<LevelSpace> spaces) {
    final l10n = AppLocalizations.of(context);
    final shown = [
      for (final space in spaces)
        if (switch (_filter) {
          _SpaceFilter.all => true,
          _SpaceFilter.free => space.status == SpaceStatus.free,
          _SpaceFilter.unknown => space.status == SpaceStatus.unknown,
        })
          space,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: QaSpacing.sm,
          runSpacing: QaSpacing.xs,
          children: [
            for (final (filter, label) in [
              (_SpaceFilter.all, l10n.zones_filterAll),
              (_SpaceFilter.free, l10n.zones_filterFree),
              (_SpaceFilter.unknown, l10n.zones_filterUnknown),
            ])
              ChoiceChip(
                label: Text(label),
                selected: _filter == filter,
                onSelected: (_) => setState(() => _filter = filter),
              ),
          ],
        ),
        const SizedBox(height: QaSpacing.md),
        if (shown.isEmpty)
          QaEmptyState(
            icon: Icons.local_parking_rounded,
            title: l10n.zones_listEmpty,
            compact: true,
          )
        else
          QaCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < shown.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  _SpaceRow(space: shown[i]),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

/// Mapa o lista del nivel: dos opciones excluyentes con texto e ícono.
class _ViewSwitch extends StatelessWidget {
  const _ViewSwitch({required this.view, required this.onChanged});

  final _LevelView view;
  final ValueChanged<_LevelView> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.zones_viewLabel,
      container: true,
      child: QaSegmentedToggle<_LevelView>(
        segments: [
          QaSegment(
            value: _LevelView.map,
            icon: Icons.map_outlined,
            label: l10n.zones_viewMap,
          ),
          QaSegment(
            value: _LevelView.list,
            icon: Icons.format_list_bulleted,
            label: l10n.zones_viewList,
          ),
        ],
        selected: view,
        onChanged: onChanged,
      ),
    );
  }
}

/// Un espacio de la lista: su identificador, su estado con ícono y texto y,
/// si no tiene datos, el motivo (US08).
class _SpaceRow extends StatelessWidget {
  const _SpaceRow({required this.space});

  final LevelSpace space;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;
    final unknown = space.status == SpaceStatus.unknown;
    final state = spaceStatusLabel(l10n, space.status);
    final reason = unknown
        ? unknownReasonLabel(l10n, space.unknownReason)
        : null;

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: l10n.zones_spaceSemantics(
        space.label,
        [state, ?reason].join(', '),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: QaSpacing.minTapTarget),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: QaSpacing.lg,
            vertical: QaSpacing.sm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      space.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (reason != null)
                      Text(
                        reason,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceMuted,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: QaSpacing.md),
              QaStatusChip(tone: toneOfSpace(space.status), label: state),
            ],
          ),
        ),
      ),
    );
  }
}

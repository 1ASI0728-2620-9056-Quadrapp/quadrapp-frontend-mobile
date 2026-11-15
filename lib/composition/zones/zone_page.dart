// US06, US08
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quadrapp_mobile/composition/zones/area_card.dart';
import 'package:quadrapp_mobile/composition/zones/area_summary_card.dart';
import 'package:quadrapp_mobile/composition/zones/zones_cubit.dart';
import 'package:quadrapp_mobile/composition/zones/zones_state.dart';
import 'package:quadrapp_mobile/composition/zones/zones_state_gate.dart';
import 'package:quadrapp_mobile/composition/zones/zones_sync.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';
import 'package:quadrapp_mobile/core/time/countdown.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

/// Pabellón (`/zones/:zoneId`): lo que cubre, su resumen y sus niveles
/// (sótanos o pisos) con libres, sin datos y disponibilidad. Tocar un nivel
/// abre su mapa. Un pabellón que ya no existe en la distribución (cambió, TS13)
/// lo dice y ofrece volver.
class ZonePage extends StatelessWidget {
  const ZonePage({
    required this.zoneId,
    required this.clock,
    required this.onBack,
    required this.onOpenLevel,
    this.ticker,
    super.key,
  });

  final ZoneId zoneId;
  final Clock clock;
  final VoidCallback onBack;
  final void Function(ZoneId zoneId, LevelId levelId) onOpenLevel;
  final Ticker? ticker;

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
          final zone = overview?.zoneById(zoneId);
          return QaTabPage(
            title: zone?.name ?? l10n.title_zones,
            onBack: onBack,
            backLabel: l10n.zones_backToZones,
            onRefresh: () => context.read<ZonesCubit>().refresh(),
            children: [
              ZonesStateGate(
                clock: clock,
                ticker: ticker ?? _everySecond,
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
    final zone = overview.zoneById(zoneId);

    // Sin distribución (parcial) no hay pabellón que mostrar: el aviso de la
    // pantalla ya lo dice.
    if (overview.layout == null) return const SizedBox.shrink();
    if (zone == null) {
      return QaEmptyState(
        illustration: QaIllustrationKind.parking,
        title: l10n.zones_notFoundTitle,
        message: l10n.zones_notFoundMessage,
        actionLabel: l10n.zones_backToZones,
        onAction: onBack,
        compact: true,
      );
    }

    final counts = overview.countsOfZone(zone.id);
    final description = zone.description;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (description != null) ...[
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: QaSpacing.md),
        ],
        AreaSummaryCard(counts: counts),
        if ((counts?.unknown ?? 0) > 0) ...[
          const SizedBox(height: QaSpacing.lg),
          QaBanner(
            kind: QaBannerKind.stale,
            icon: Icons.info_outline_rounded,
            message: l10n.zones_unknownBanner,
          ),
        ],
        const SizedBox(height: QaSpacing.xl),
        Semantics(
          header: true,
          child: Text(
            l10n.zones_levelsHeading,
            style: theme.textTheme.titleSmall,
          ),
        ),
        const SizedBox(height: QaSpacing.md),
        for (var i = 0; i < zone.levels.length; i++)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : QaSpacing.md),
            child: QaStagger(
              index: i,
              child: AreaCard(
                title: zone.levels[i].name,
                counts: overview.countsOfLevel(zone.levels[i].id),
                saturationThresholdPct: overview.lot.saturationThresholdPct,
                hint: l10n.zones_openLevelMap,
                onTap: () => onOpenLevel(zone.id, zone.levels[i].id),
              ),
            ),
          ),
      ],
    );
  }
}

// US06, US07, US08
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quadrapp_mobile/composition/sede/sede_cubit.dart';
import 'package:quadrapp_mobile/composition/zones/area_card.dart';
import 'package:quadrapp_mobile/composition/zones/area_summary_card.dart';
import 'package:quadrapp_mobile/composition/zones/zone_filter_sheet.dart';
import 'package:quadrapp_mobile/composition/zones/zones_cubit.dart';
import 'package:quadrapp_mobile/composition/zones/zones_state.dart';
import 'package:quadrapp_mobile/composition/zones/zones_state_gate.dart';
import 'package:quadrapp_mobile/composition/zones/zones_sync.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';
import 'package:quadrapp_mobile/core/time/countdown.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

/// Zonas (`/zones`): el resumen de la sede (capacidad, libres y sin datos), el
/// aviso de los espacios sin datos y una tarjeta por pabellón con su
/// disponibilidad. Tocar una tarjeta abre los niveles del pabellón; si el
/// pabellón tiene un solo nivel, abre directo su mapa. El filtro de la barra
/// abre «Ordenar y filtrar».
///
/// Cinco estados (docs/05): skeleton al cargar, vacío (la sede sin pabellones
/// o un filtro que los oculta todos), error recuperable, parcial o
/// desactualizado y éxito. Deslizar hacia abajo recarga. Sin sede elegida,
/// pide elegirla.
class ZonesTabPage extends StatefulWidget {
  const ZonesTabPage({
    required this.clock,
    required this.tabIndex,
    required this.onOpenZone,
    required this.onOpenLevel,
    this.ticker,
    super.key,
  });

  final Clock clock;

  /// Posición de la pestaña en la barra inferior.
  final int tabIndex;
  final ValueChanged<ZoneId> onOpenZone;
  final void Function(ZoneId zoneId, LevelId levelId) onOpenLevel;

  /// Reloj de la antigüedad; en pruebas, uno que no corre.
  final Ticker? ticker;

  @override
  State<ZonesTabPage> createState() => _ZonesTabPageState();
}

class _ZonesTabPageState extends State<ZonesTabPage> {
  ZoneListOptions _options = const ZoneListOptions();

  Future<void> _refresh() async {
    final sede = context.read<SedeCubit>();
    final selected = switch (sede.state) {
      ViewData(:final data) => data.selected,
      _ => null,
    };
    if (selected == null) return sede.load();
    await context.read<ZonesCubit>().refresh();
  }

  void _openFilter() {
    unawaited(
      showZoneFilterSheet(
        context,
        initial: _options,
        onChanged: (options) => setState(() => _options = options),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ZonesSync(
      child: BlocBuilder<ZonesCubit, ViewState<ZonesOverview>>(
        builder: (context, state) {
          final hasZones = switch (state) {
            ViewData(:final data) => data.layout != null,
            ViewPartial(:final data) => data.layout != null,
            _ => false,
          };
          return QaTabPage(
            tabIndex: widget.tabIndex,
            title: l10n.title_zones,
            action: hasZones
                ? QaTopBarAction(
                    icon: _options.isDefault
                        ? Icons.tune_rounded
                        : Icons.filter_alt_rounded,
                    label: _options.isDefault
                        ? l10n.zones_filterAction
                        : l10n.zones_filterActionActive,
                    onPressed: _openFilter,
                  )
                : null,
            onRefresh: _refresh,
            children: [
              ZonesStateGate(
                clock: widget.clock,
                ticker: widget.ticker ?? _everySecond,
                showSedeChip: true,
                builder: _content,
              ),
            ],
          );
        },
      ),
    );
  }

  static Stream<void> _everySecond() =>
      Stream<void>.periodic(const Duration(seconds: 1));

  Widget _content(BuildContext context, ZonesOverview overview) {
    final l10n = AppLocalizations.of(context);
    final zones = arrangeZones(overview, _options);
    final layoutZones = overview.layout?.zones ?? const <Zone>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AreaSummaryCard(counts: overview.lotCounts),
        if ((overview.lotCounts?.unknown ?? 0) > 0) ...[
          const SizedBox(height: QaSpacing.lg),
          QaBanner(
            kind: QaBannerKind.stale,
            icon: Icons.info_outline_rounded,
            message: l10n.zones_unknownBanner,
          ),
        ],
        const SizedBox(height: QaSpacing.lg),
        if (overview.layout != null && layoutZones.isEmpty)
          QaEmptyState(
            illustration: QaIllustrationKind.parking,
            title: l10n.zones_emptyTitle,
            message: l10n.zones_emptyMessage,
            compact: true,
          )
        else if (overview.layout != null && zones.isEmpty)
          QaEmptyState(
            illustration: QaIllustrationKind.parking,
            title: l10n.zones_noFreeTitle,
            message: l10n.zones_noFreeMessage,
            actionLabel: l10n.zones_showAll,
            onAction: () => setState(() => _options = const ZoneListOptions()),
            compact: true,
          )
        else
          for (var i = 0; i < zones.length; i++)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : QaSpacing.md),
              child: QaStagger(
                index: i,
                child: _zoneCard(context, overview, zones[i]),
              ),
            ),
      ],
    );
  }

  Widget _zoneCard(BuildContext context, ZonesOverview overview, Zone zone) {
    final l10n = AppLocalizations.of(context);
    final single = zone.levels.length == 1;
    return AreaCard(
      title: zone.name,
      subtitle: zone.description,
      counts: overview.countsOfZone(zone.id),
      saturationThresholdPct: overview.lot.saturationThresholdPct,
      hint: single ? l10n.zones_openLevelMap : l10n.zones_openLevels,
      onTap: () => single
          ? widget.onOpenLevel(zone.id, zone.levels.single.id)
          : widget.onOpenZone(zone.id),
    );
  }
}

// US05, US06, US08, TS13 (vista del administrador de universidad)
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quadrapp_mobile/composition/lots/lot_zone_card.dart';
import 'package:quadrapp_mobile/composition/lots/zone_spaces_card.dart';
import 'package:quadrapp_mobile/composition/sede/sede_cubit.dart';
import 'package:quadrapp_mobile/composition/zones/zones_cubit.dart';
import 'package:quadrapp_mobile/composition/zones/zones_state.dart';
import 'package:quadrapp_mobile/composition/zones/zones_state_gate.dart';
import 'package:quadrapp_mobile/composition/zones/zones_sync.dart';
import 'package:quadrapp_mobile/contexts/occupancy/occupancy.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';
import 'package:quadrapp_mobile/core/time/countdown.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

/// Qué zonas se listan: todas, las operativas (sin espacios desconocidos) o
/// las que piden atención (con alguno).
enum _ZoneFilter { all, ok, attention }

/// Estacionamientos (`/ops/zones`, administrador de universidad): las zonas
/// del estacionamiento elegido con su ocupación y su estado, y los espacios
/// de la zona elegida. «Ver los N» abre la zona (o directo su nivel, si tiene
/// uno solo) con el mapa y la lista que ya usa el Conductor.
///
/// Comparte con el Conductor el estado de Zonas ([ZonesCubit] y
/// [ZonesStateGate]): skeleton, sin estacionamientos, error recuperable, sin
/// conexión, dato vencido o parcial y éxito, con la antigüedad del dato.
/// Deslizar hacia abajo recarga. Los desconocidos nunca cuentan como libres.
class LotsPage extends StatefulWidget {
  const LotsPage({
    required this.clock,
    required this.tabIndex,
    required this.onOpenZone,
    required this.onOpenLevel,
    required this.onOpenAccount,
    this.onManageLayout,
    this.ticker,
    super.key,
  });

  final Clock clock;
  final int tabIndex;
  final ValueChanged<ZoneId> onOpenZone;
  final void Function(ZoneId zoneId, LevelId levelId) onOpenLevel;
  final VoidCallback onOpenAccount;

  /// «Gestionar zonas y espacios»; `null` para el operador, que no edita la
  /// distribución.
  final VoidCallback? onManageLayout;

  /// Reloj de la antigüedad; en pruebas, uno que no corre.
  final Ticker? ticker;

  @override
  State<LotsPage> createState() => _LotsPageState();
}

class _LotsPageState extends State<LotsPage> {
  _ZoneFilter _filter = _ZoneFilter.all;
  ZoneId? _selected;
  SpaceStatus? _spaceFilter;

  Future<void> _refresh() async {
    final sede = context.read<SedeCubit>();
    final selected = switch (sede.state) {
      ViewData(:final data) => data.selected,
      _ => null,
    };
    if (selected == null) return sede.load();
    await context.read<ZonesCubit>().refresh();
  }

  static Stream<void> _everySecond() =>
      Stream<void>.periodic(const Duration(seconds: 1));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ZonesSync(
      child: QaTabPage(
        tabIndex: widget.tabIndex,
        title: l10n.nav_zones,
        action: QaTopBarAction(
          icon: Icons.account_circle_outlined,
          label: l10n.account_open,
          onPressed: widget.onOpenAccount,
        ),
        onRefresh: _refresh,
        children: [
          ZonesStateGate(
            clock: widget.clock,
            ticker: widget.ticker ?? _everySecond,
            showSedeChip: true,
            builder: _content,
          ),
        ],
      ),
    );
  }

  bool _matches(ZonesOverview overview, Zone zone) {
    final unknown = overview.countsOfZone(zone.id)?.unknown;
    return switch (_filter) {
      _ZoneFilter.all => true,
      _ZoneFilter.ok => unknown == 0,
      _ZoneFilter.attention => unknown != null && unknown > 0,
    };
  }

  Widget _content(BuildContext context, ZonesOverview overview) {
    final l10n = AppLocalizations.of(context);
    final zones = overview.layout?.zones ?? const <Zone>[];
    final header = QaTabHeader(
      title: l10n.lots_title,
      subtitle: l10n.lots_subtitle(overview.lot.name, zones.length),
    );

    final onManage = widget.onManageLayout;
    final manage = onManage == null
        ? null
        : QaButton(
            label: l10n.lots_manage,
            icon: Icons.tune_rounded,
            expand: true,
            onPressed: onManage,
          );

    if (zones.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: QaSpacing.xl),
          QaEmptyState(
            illustration: QaIllustrationKind.parking,
            title: l10n.lots_noZones,
            compact: true,
          ),
          if (manage != null) ...[
            const SizedBox(height: QaSpacing.lg),
            manage,
          ],
        ],
      );
    }

    final visible = [
      for (final zone in zones)
        if (_matches(overview, zone)) zone,
    ];
    // La elegida, si sigue a la vista; si no, la primera que pide atención.
    final selected =
        visible.where((zone) => zone.id == _selected).firstOrNull ??
        visible
            .where((z) => (overview.countsOfZone(z.id)?.unknown ?? 0) > 0)
            .firstOrNull ??
        visible.firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: QaSpacing.lg),
        QaSegmentedToggle<_ZoneFilter>(
          segments: [
            QaSegment(value: _ZoneFilter.all, label: l10n.lots_filterAll),
            QaSegment(value: _ZoneFilter.ok, label: l10n.lots_filterOk),
            QaSegment(
              value: _ZoneFilter.attention,
              label: l10n.lots_filterAttention,
            ),
          ],
          selected: _filter,
          onChanged: (filter) => setState(() => _filter = filter),
        ),
        const SizedBox(height: QaSpacing.lg),
        if (visible.isEmpty)
          QaEmptyState(
            icon: Icons.filter_alt_off_outlined,
            title: l10n.lots_emptyFilter,
            compact: true,
          )
        else ...[
          for (final zone in visible) ...[
            LotZoneCard(
              zone: zone,
              counts: overview.countsOfZone(zone.id),
              saturationThresholdPct: overview.lot.saturationThresholdPct,
              selected: zone.id == selected?.id,
              onTap: () => setState(() {
                _selected = zone.id;
                _spaceFilter = null;
              }),
            ),
            const SizedBox(height: QaSpacing.md),
          ],
          if (selected != null) ...[
            const SizedBox(height: QaSpacing.sm),
            ZoneSpacesCard(
              zone: selected,
              spaces: [
                for (final level in selected.levels)
                  ...overview.spacesOf(level),
              ],
              filter: _spaceFilter,
              onFilter: (status) => setState(() => _spaceFilter = status),
              onSeeAll: () => selected.levels.length == 1
                  ? widget.onOpenLevel(selected.id, selected.levels.single.id)
                  : widget.onOpenZone(selected.id),
            ),
          ],
        ],
        if (manage != null) ...[
          const SizedBox(height: QaSpacing.lg),
          manage,
        ],
      ],
    );
  }
}

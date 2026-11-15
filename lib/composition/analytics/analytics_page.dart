// US21, US22, US34, TS11
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quadrapp_mobile/composition/analytics/analytics_cards.dart';
import 'package:quadrapp_mobile/composition/analytics/analytics_cubit.dart';
import 'package:quadrapp_mobile/composition/analytics/analytics_overview.dart';
import 'package:quadrapp_mobile/composition/analytics/export_report_sheet.dart';
import 'package:quadrapp_mobile/composition/sede/live_status.dart';
import 'package:quadrapp_mobile/composition/sede/sede_chip.dart';
import 'package:quadrapp_mobile/composition/sede/sede_cubit.dart';
import 'package:quadrapp_mobile/composition/sede/sede_gate.dart';
import 'package:quadrapp_mobile/composition/sede/sede_state.dart';
import 'package:quadrapp_mobile/composition/zones/zones_cubit.dart';
import 'package:quadrapp_mobile/composition/zones/zones_state.dart';
import 'package:quadrapp_mobile/composition/zones/zones_sync.dart';
import 'package:quadrapp_mobile/contexts/analytics/analytics.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';
import 'package:quadrapp_mobile/core/time/app_time_formatter.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

/// Analítica y precisión (`/ops/analytics`, roles `ADMIN` y `OPERATOR`) del
/// estacionamiento elegido:
/// - el periodo (hoy, 7 o 30 días, US21 esc. 1);
/// - la ocupación del periodo, de todo el estacionamiento o de una zona
///   (US21 esc. 2), con el pronóstico y el riesgo de hoy y las horas pico
///   (US22);
/// - la precisión del pronóstico por horizonte y versión del modelo (US34);
/// - «Exportar reporte»: el servidor lo envía al correo institucional.
///
/// Cinco estados (docs/05): skeleton al cargar, vacío (sin estacionamientos o
/// periodo sin registros, en su tarjeta), error recuperable (incluido el
/// 403), parcial (lo que no llegó lo dice su tarjeta, con un aviso para
/// reintentar) y éxito. Deslizar hacia abajo recarga.
class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({
    required this.clock,
    required this.tabIndex,
    required this.onOpenAccount,
    super.key,
  });

  final Clock clock;

  /// Posición de la pestaña en la barra inferior.
  final int tabIndex;

  /// El avatar de la barra superior lleva a la cuenta.
  final VoidCallback onOpenAccount;

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  static const AppTimeFormatter _time = AppTimeFormatter();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncLot(context.read<SedeCubit>().state);
    });
  }

  static ParkingLot? _selectedOf(ViewState<SedeSelection> state) =>
      state is ViewData<SedeSelection> ? state.data.selected : null;

  void _syncLot(ViewState<SedeSelection> state) {
    final lot = _selectedOf(state);
    if (lot != null) unawaited(context.read<AnalyticsCubit>().load(lot.id));
  }

  Future<void> _refresh() async {
    final sede = context.read<SedeCubit>();
    if (_selectedOf(sede.state) == null) return sede.load();
    await context.read<AnalyticsCubit>().refresh();
  }

  /// Las zonas del estacionamiento elegido, de la distribución que ya
  /// comparte la experiencia de Operación.
  static List<Zone> _zonesOf(
    ParkingLot lot,
    ViewState<ZonesOverview> state,
  ) {
    final overview = switch (state) {
      ViewData(:final data) => data,
      ViewPartial(:final data) => data,
      ViewLoading(:final previous) => previous,
      ViewError(:final previous) => previous,
      _ => null,
    };
    if (overview == null || overview.lot.id != lot.id) return const [];
    return overview.layout?.zones ?? const [];
  }

  Future<void> _pickZone(List<Zone> zones, ZoneId? selected) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<AnalyticsCubit>();
    final picked = await showQaBottomSheet<({ZoneId? id})>(
      context,
      builder: (context) => QaBottomSheet(
        title: l10n.analytics_zoneSheetTitle,
        subtitle: l10n.analytics_zoneSheetSubtitle,
        closeLabel: l10n.layout_close,
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ZoneOption(
                label: l10n.analytics_wholeLot,
                selected: selected == null,
                onTap: () => Navigator.of(context).pop((id: null)),
              ),
              for (final zone in zones)
                _ZoneOption(
                  label: zone.name,
                  selected: zone.id == selected,
                  onTap: () => Navigator.of(context).pop((id: zone.id)),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    unawaited(cubit.selectZone(picked.id));
  }

  Future<void> _export(ParkingLot lot) async {
    final cubit = context.read<AnalyticsCubit>();
    final delivery = await showExportReportSheet(
      context,
      lotName: lot.name,
      today: _time.toLima(widget.clock.now()),
      rangeOf: cubit.rangeOf,
      onExport: cubit.exportReport,
    );
    if (delivery == null || !mounted) return;
    QaHaptics.success();
    showQaSnackbar(
      context,
      message: AppLocalizations.of(context).analytics_exportSent(
        delivery.sentTo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // ZonesSync lleva la sede elegida a las zonas compartidas: el filtro de
    // zona las necesita aunque no se haya abierto Estacionamientos.
    return ZonesSync(
      child: BlocListener<SedeCubit, ViewState<SedeSelection>>(
        listenWhen: (before, after) =>
            _selectedOf(before)?.id != _selectedOf(after)?.id,
        listener: (context, state) => _syncLot(state),
        child: QaTabPage(
          tabIndex: widget.tabIndex,
          title: l10n.nav_analytics,
          action: QaTopBarAction(
            icon: Icons.account_circle_outlined,
            label: l10n.account_open,
            onPressed: widget.onOpenAccount,
          ),
          onRefresh: _refresh,
          children: [
            SedeGate(
              skeleton: _skeleton(l10n),
              promptTitle: l10n.shift_promptTitle,
              promptMessage: l10n.shift_promptMessage,
              builder: (context, lot) =>
                  BlocBuilder<AnalyticsCubit, ViewState<AnalyticsOverview>>(
                    builder: (context, state) =>
                        BlocBuilder<ZonesCubit, ViewState<ZonesOverview>>(
                          builder: (context, zonesState) => _body(
                            context,
                            l10n,
                            lot,
                            state,
                            _zonesOf(lot, zonesState),
                          ),
                        ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------ cuerpo

  Widget _body(
    BuildContext context,
    AppLocalizations l10n,
    ParkingLot lot,
    ViewState<AnalyticsOverview> state,
    List<Zone> zones,
  ) {
    final cubit = context.read<AnalyticsCubit>();
    final overview = switch (state) {
      ViewData(:final data) => data,
      ViewPartial(:final data) => data,
      ViewLoading(:final previous) => previous,
      ViewError(:final previous) => previous,
      _ => null,
    };
    final period = cubit.period;
    final toggle = QaSegmentedToggle<AnalyticsPeriod>(
      segments: [
        for (final p in AnalyticsPeriod.values)
          QaSegment(value: p, label: periodLabel(l10n, p)),
      ],
      selected: period,
      onChanged: (p) => unawaited(cubit.selectPeriod(p)),
    );

    if (overview == null || overview.lotId != lot.id) {
      return switch (state) {
        ViewError(:final failure) => _failure(context, l10n, lot, failure),
        _ => _skeleton(l10n),
      };
    }

    final loading = state is ViewLoading<AnalyticsOverview>;
    final failure = state is ViewError<AnalyticsOverview>
        ? state.failure
        : null;
    final zoneId = overview.zoneId;
    final zoneName = zoneId == null
        ? null
        : zones.where((z) => z.id == zoneId).firstOrNull?.name;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(
          l10n,
          subtitle: l10n.analytics_subtitle(
            lot.name,
            _periodPhrase(l10n, period),
          ),
        ),
        // La recarga falló: se sigue viendo lo último, con el aviso.
        if (failure != null) ...[
          const SizedBox(height: QaSpacing.lg),
          QaBanner(
            kind: QaBannerKind.error,
            message: failure is ForbiddenFailure
                ? l10n.analytics_forbidden
                : loadErrorText(l10n, failure),
            actionLabel: l10n.lots_retry,
            onAction: () => unawaited(cubit.refresh()),
          ),
        ] else if (overview.isPartial && !loading) ...[
          const SizedBox(height: QaSpacing.lg),
          QaBanner(
            kind: QaBannerKind.stale,
            message: l10n.analytics_partial,
            actionLabel: l10n.lots_retry,
            onAction: () => unawaited(cubit.refresh()),
          ),
        ],
        const SizedBox(height: QaSpacing.lg),
        toggle,
        const SizedBox(height: QaSpacing.lg),
        QaAnimatedSize(
          child: Opacity(
            opacity: loading ? 0.6 : 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OccupancyHistoryCard(
                  overview: overview,
                  lot: lot,
                  clock: widget.clock,
                  zoneName: zoneName,
                  onPickZone: zones.isEmpty || loading
                      ? null
                      : () => unawaited(_pickZone(zones, zoneId)),
                ),
                const SizedBox(height: QaSpacing.lg),
                ForecastAccuracyCard(
                  accuracy: overview.accuracy,
                  period: overview.period,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: QaSpacing.lg),
        QaButton(
          label: l10n.analytics_exportOpen,
          icon: Icons.download_rounded,
          variant: QaButtonVariant.tonal,
          expand: true,
          onPressed: () => unawaited(_export(lot)),
        ),
      ],
    );
  }

  String _periodPhrase(AppLocalizations l10n, AnalyticsPeriod period) =>
      switch (period) {
        AnalyticsPeriod.today => l10n.analytics_evaluationToday,
        AnalyticsPeriod.last7Days => l10n.analytics_evaluationDays(7),
        AnalyticsPeriod.last30Days => l10n.analytics_evaluationDays(30),
      };

  /// La sede, el título y, si lo hay, el subtítulo.
  Widget _heading(AppLocalizations l10n, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Align(alignment: Alignment.centerLeft, child: SedeChip()),
        const SizedBox(height: QaSpacing.lg),
        QaTabHeader(title: l10n.analytics_title, subtitle: subtitle),
      ],
    );
  }

  /// Nada que mostrar: el 403 y lo demás son errores recuperables.
  Widget _failure(
    BuildContext context,
    AppLocalizations l10n,
    ParkingLot lot,
    Failure failure,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(l10n, subtitle: lot.name),
        const SizedBox(height: QaSpacing.xl),
        QaErrorState(
          title: l10n.analytics_errorTitle,
          message: failure is ForbiddenFailure
              ? l10n.analytics_forbidden
              : loadErrorText(l10n, failure),
          retryLabel: l10n.lots_retry,
          onRetry: () => unawaited(context.read<AnalyticsCubit>().refresh()),
        ),
      ],
    );
  }

  Widget _skeleton(AppLocalizations l10n) {
    return QaLoadingRegion(
      semanticLabel: l10n.analytics_loading,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: QaSkeleton(width: 140, height: 36),
          ),
          SizedBox(height: QaSpacing.lg),
          QaSkeleton(width: 240, height: 32),
          SizedBox(height: QaSpacing.sm),
          QaSkeleton.line(width: 200),
          SizedBox(height: QaSpacing.lg),
          QaSkeleton(height: 48, borderRadius: QaRadii.cardRadius),
          SizedBox(height: QaSpacing.lg),
          QaSkeleton(height: 300, borderRadius: QaRadii.cardRadius),
          SizedBox(height: QaSpacing.lg),
          QaSkeleton(height: 220, borderRadius: QaRadii.cardRadius),
        ],
      ),
    );
  }
}

/// Una zona en el filtro: el nombre y, si es la elegida, una marca (no solo
/// color).
class _ZoneOption extends StatelessWidget {
  const _ZoneOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.qaColors;
    return Semantics(
      selected: selected,
      button: true,
      inMutuallyExclusiveGroup: true,
      child: ListTile(
        minTileHeight: QaSpacing.minTapTarget + 8,
        title: Text(label),
        trailing: selected
            ? Icon(Icons.check_rounded, color: colors.primary)
            : null,
        selected: selected,
        onTap: onTap,
      ),
    );
  }
}

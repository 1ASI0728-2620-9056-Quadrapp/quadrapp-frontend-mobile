// US04, US05, US06, US07, US08, TS13
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quadrapp_mobile/composition/arrival/lot_age_text.dart';
import 'package:quadrapp_mobile/composition/sede/live_status.dart';
import 'package:quadrapp_mobile/composition/sede/sede_chip.dart';
import 'package:quadrapp_mobile/composition/sede/sede_gate.dart';
import 'package:quadrapp_mobile/composition/sede/sede_no_data_card.dart';
import 'package:quadrapp_mobile/composition/zones/zones_cubit.dart';
import 'package:quadrapp_mobile/composition/zones/zones_state.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';
import 'package:quadrapp_mobile/core/time/app_time_formatter.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';
import 'package:quadrapp_mobile/core/time/countdown.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

Stream<void> _everySecond() =>
    Stream<void>.periodic(const Duration(seconds: 1));

/// Lo común de las tres pantallas de Zonas: la sede elegida, el estado real de
/// la conexión, los avisos (sin conexión, datos vencidos, parcial, error) y la
/// antigüedad del dato; en medio, el contenido de cada pantalla ([builder]).
///
/// Cubre los estados del cubit: skeleton al cargar, error recuperable, la sede
/// sin distribución publicada (sin disponibilidad, US04 esc. 2), parcial o
/// desactualizado y éxito. La antigüedad se recalcula cada segundo con la hora
/// del servidor más el tiempo transcurrido (nunca con el reloj del teléfono):
/// [clock] y [ticker] se inyectan.
class ZonesStateGate extends StatefulWidget {
  const ZonesStateGate({
    required this.clock,
    required this.builder,
    this.showSedeChip = false,
    this.ticker = _everySecond,
    super.key,
  });

  final Clock clock;
  final Widget Function(BuildContext context, ZonesOverview overview) builder;

  /// En Zonas, el selector de sede; en el pabellón y el nivel, solo su nombre.
  final bool showSedeChip;
  final Ticker ticker;

  @override
  State<ZonesStateGate> createState() => _ZonesStateGateState();
}

class _ZonesStateGateState extends State<ZonesStateGate> {
  static const AppTimeFormatter _time = AppTimeFormatter();

  StreamSubscription<void>? _ticks;

  @override
  void initState() {
    super.initState();
    _ticks = widget.ticker().listen((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    unawaited(_ticks?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SedeGate(
      skeleton: _skeleton(l10n),
      builder: (context, lot) =>
          BlocBuilder<ZonesCubit, ViewState<ZonesOverview>>(
            builder: (context, state) => switch (state) {
              ViewInitial() ||
              ViewEmpty() ||
              ViewLoading(previous: null) => _skeleton(l10n),
              ViewError(:final failure, previous: null) => Padding(
                padding: const EdgeInsets.only(top: QaSpacing.xxxl),
                child: QaErrorState(
                  title: l10n.lots_errorTitle,
                  message: loadErrorText(l10n, failure),
                  retryLabel: l10n.lots_retry,
                  onRetry: () => unawaited(context.read<ZonesCubit>().load()),
                ),
              ),
              ViewError(:final failure, :final previous?) => _content(
                context,
                l10n,
                previous,
                error: QaBanner(
                  kind: QaBannerKind.error,
                  message: loadErrorText(l10n, failure),
                  actionLabel: l10n.lots_retry,
                  onAction: () => unawaited(context.read<ZonesCubit>().load()),
                ),
              ),
              ViewLoading(:final previous?) => _content(
                context,
                l10n,
                previous,
              ),
              ViewData(:final data) => _content(context, l10n, data),
              ViewPartial(:final data) => _content(context, l10n, data),
            },
          ),
    );
  }

  Widget _content(
    BuildContext context,
    AppLocalizations l10n,
    ZonesOverview overview, {
    QaBanner? error,
  }) {
    final theme = Theme.of(context);
    final colors = context.qaColors;
    final locale = Localizations.localeOf(context).languageCode;
    final occupancy = overview.occupancy;
    final stale =
        occupancy != null && occupancy.freshness.isStale(widget.clock);
    final live = overview.hasNoData
        ? null
        : liveBadgeOf(l10n, offline: overview.isOffline, link: overview.link);

    final notices = <Widget>[
      ?error,
      if (overview.isOffline)
        QaBanner(kind: QaBannerKind.offline, message: l10n.lots_offlineBanner),
      if (stale)
        QaBanner(
          kind: QaBannerKind.stale,
          message: l10n.lots_staleSince(
            _time.formatTime(occupancy.consolidatedAt, locale),
          ),
        ),
      if (overview.isPartial)
        QaBanner(
          kind: QaBannerKind.error,
          message: overview.layout == null
              ? l10n.zones_partialLayout
              : l10n.zones_partialOccupancy,
          actionLabel: l10n.lots_retry,
          onAction: () => unawaited(context.read<ZonesCubit>().load()),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: QaSpacing.md,
          runSpacing: QaSpacing.sm,
          children: [
            if (widget.showSedeChip)
              const SedeChip()
            else
              Text(
                overview.lot.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceMuted,
                ),
              ),
            ?live,
          ],
        ),
        for (final notice in notices) ...[
          const SizedBox(height: QaSpacing.lg),
          notice,
        ],
        const SizedBox(height: QaSpacing.lg),
        if (overview.hasNoData)
          SedeNoDataCard(
            lotName: overview.lot.name,
            onPickAnother: () => unawaited(showSedePicker(context)),
          )
        else ...[
          widget.builder(context, overview),
          if (occupancy != null) ...[
            const SizedBox(height: QaSpacing.lg),
            Text(
              l10n.lots_updatedAgo(
                lotAgeText(l10n, occupancy.freshness.age(widget.clock)),
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ],
    );
  }

  /// El selector, el resumen y las tarjetas en carga: bloques grises con la
  /// misma disposición que el contenido real.
  Widget _skeleton(AppLocalizations l10n) {
    return QaLoadingRegion(
      semanticLabel: l10n.zones_loading,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: QaSkeleton(width: 140, height: 36),
          ),
          const SizedBox(height: QaSpacing.lg),
          const QaCard(
            child: Row(
              children: [
                Expanded(child: QaSkeleton(height: 44)),
                SizedBox(width: QaSpacing.md),
                Expanded(child: QaSkeleton(height: 44)),
                SizedBox(width: QaSpacing.md),
                Expanded(child: QaSkeleton(height: 44)),
              ],
            ),
          ),
          for (var i = 0; i < 3; i++) ...[
            const SizedBox(height: QaSpacing.md),
            const QaCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  QaSkeleton(width: 160, height: 20),
                  SizedBox(height: QaSpacing.sm),
                  QaSkeleton(width: 110, height: 14),
                  SizedBox(height: QaSpacing.md),
                  QaSkeleton(width: 100, height: 26),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

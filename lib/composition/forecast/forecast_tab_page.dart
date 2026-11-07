// US04, US09, US10, US11, US12, US13, US15
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quadrapp_mobile/composition/arrival/lot_age_text.dart';
import 'package:quadrapp_mobile/composition/eta/eta_copy.dart';
import 'package:quadrapp_mobile/composition/eta/eta_cubit.dart';
import 'package:quadrapp_mobile/composition/eta/eta_sheet.dart';
import 'package:quadrapp_mobile/composition/forecast/eta_hero.dart';
import 'package:quadrapp_mobile/composition/forecast/forecast_cubit.dart';
import 'package:quadrapp_mobile/composition/forecast/forecast_detail_sheet.dart';
import 'package:quadrapp_mobile/composition/forecast/forecast_row_card.dart';
import 'package:quadrapp_mobile/composition/forecast/forecast_state.dart';
import 'package:quadrapp_mobile/composition/sede/live_status.dart';
import 'package:quadrapp_mobile/composition/sede/sede_chip.dart';
import 'package:quadrapp_mobile/composition/sede/sede_cubit.dart';
import 'package:quadrapp_mobile/composition/sede/sede_gate.dart';
import 'package:quadrapp_mobile/composition/sede/sede_no_data_card.dart';
import 'package:quadrapp_mobile/composition/sede/sede_state.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/prediction_advisory.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';
import 'package:quadrapp_mobile/core/time/app_time_formatter.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';
import 'package:quadrapp_mobile/core/time/countdown.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

Stream<void> _everySecond() =>
    Stream<void>.periodic(const Duration(seconds: 1));

/// Predicción (`/forecast`): cuándo llegas y cómo puede cambiar la
/// disponibilidad a 15, 30, 45 y 60 minutos. La tarjeta de petróleo muestra el
/// tiempo de llegada («Si sales ahora · Llegas en 27 min») y abre «¿Cuándo
/// llegas?»; cada horizonte muestra la probabilidad de encontrar espacio, su
/// categoría y la confianza, y abre su detalle (ocupación esperada,
/// saturación prevista, cuándo se generó). El calendario de la barra también
/// abre «¿Cuándo llegas?».
///
/// Cinco estados (docs/05): skeleton al cargar, vacío (la sede sin
/// pronósticos), error recuperable, parcial (horizontes faltantes o vencidos,
/// sin el detalle de los pronósticos, confianza baja) y éxito. Deslizar hacia
/// abajo recarga. Sin sede elegida, pide elegirla.
///
/// Un pronóstico vencido deja de presentarse como actual mientras la pantalla
/// está abierta: el reloj se recalcula cada segundo con la hora del servidor
/// más el tiempo transcurrido (nunca con el reloj del teléfono): [clock] y
/// [ticker] se inyectan.
class ForecastTabPage extends StatefulWidget {
  const ForecastTabPage({
    required this.clock,
    required this.tabIndex,
    this.ticker = _everySecond,
    super.key,
  });

  final Clock clock;

  /// Posición de la pestaña en la barra inferior.
  final int tabIndex;
  final Ticker ticker;

  @override
  State<ForecastTabPage> createState() => _ForecastTabPageState();
}

class _ForecastTabPageState extends State<ForecastTabPage> {
  static const AppTimeFormatter _time = AppTimeFormatter();

  StreamSubscription<void>? _ticks;

  @override
  void initState() {
    super.initState();
    _ticks = widget.ticker().listen((_) {
      if (mounted) setState(() {});
    });
    // La sede que ya esté lista (al volver a esta pestaña).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncLot(context.read<SedeCubit>().state);
    });
  }

  @override
  void dispose() {
    unawaited(_ticks?.cancel());
    super.dispose();
  }

  void _syncLot(ViewState<SedeSelection> state) =>
      unawaited(context.read<ForecastCubit>().setLot(_selectedOf(state)));

  static ParkingLot? _selectedOf(ViewState<SedeSelection> state) =>
      state is ViewData<SedeSelection> ? state.data.selected : null;

  Future<void> _refresh() async {
    final sede = context.read<SedeCubit>();
    if (_selectedOf(sede.state) == null) return sede.load();
    await context.read<ForecastCubit>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocListener<SedeCubit, ViewState<SedeSelection>>(
      listenWhen: (before, after) =>
          _selectedOf(before)?.id != _selectedOf(after)?.id,
      listener: (context, state) => _syncLot(state),
      child: QaTabPage(
        tabIndex: widget.tabIndex,
        title: l10n.title_forecast,
        action: QaTopBarAction(
          icon: Icons.calendar_month_outlined,
          label: l10n.forecast_etaAction,
          onPressed: () => unawaited(showEtaSheet(context)),
        ),
        onRefresh: _refresh,
        children: [
          SedeGate(
            skeleton: _skeleton(l10n),
            builder: (context, lot) =>
                BlocBuilder<ForecastCubit, ViewState<ForecastOverview>>(
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
                        onRetry: () =>
                            unawaited(context.read<ForecastCubit>().load()),
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
                        onAction: () =>
                            unawaited(context.read<ForecastCubit>().load()),
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
          ),
        ],
      ),
    );
  }

  Widget _content(
    BuildContext context,
    AppLocalizations l10n,
    ForecastOverview overview, {
    QaBanner? error,
  }) {
    const gap = SizedBox(height: QaSpacing.lg);
    const header = Align(
      alignment: AlignmentDirectional.centerStart,
      child: SedeChip(),
    );

    if (overview.hasNoData) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          gap,
          SedeNoDataCard(
            lotName: overview.lot.name,
            onPickAnother: () => unawaited(showSedePicker(context)),
          ),
        ],
      );
    }

    final rows = overview.rows(widget.clock);
    final missing = rows.any((r) => r.status == ForecastRowStatus.missing);
    final expired = rows.any((r) => r.status == ForecastRowStatus.expired);
    // El aviso de poco historial es de la sede (contingencia); la confianza
    // baja de un horizonte lejano se dice en su propia tarjeta.
    final fallback = rows.any((r) => r.isFallback);
    final notices = <Widget>[
      ?error,
      if (overview.forecasts == null)
        QaBanner(
          kind: QaBannerKind.error,
          message: l10n.forecast_partialDetails,
          actionLabel: l10n.lots_retry,
          onAction: () => unawaited(context.read<ForecastCubit>().load()),
        ),
      if (!overview.hasNothing && missing)
        QaBanner(
          kind: QaBannerKind.stale,
          icon: Icons.info_outline_rounded,
          message: l10n.forecast_partialMissing,
        ),
      if (expired)
        QaBanner(
          kind: QaBannerKind.stale,
          icon: Icons.schedule_rounded,
          message: l10n.forecast_partialExpired,
        ),
      if (fallback)
        QaBanner(
          kind: QaBannerKind.stale,
          icon: Icons.info_outline_rounded,
          message: l10n.forecast_lowConfidenceBanner,
        ),
    ];

    return BlocBuilder<EtaCubit, EtaState>(
      builder: (context, eta) {
        final arrival = eta.estimate == null
            ? null
            : ForecastHorizon.nearestTo(eta.estimate!.minutes.value);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            gap,
            EtaHero(
              eta: eta,
              updatedAgo:
                  eta.estimate?.isEstimated == true && eta.updatedAt != null
                  ? etaUpdatedText(
                      l10n,
                      _since(widget.clock.monotonic() - eta.updatedAt!),
                    )
                  : null,
              onTap: () => unawaited(showEtaSheet(context)),
            ),
            for (final notice in notices) ...[gap, notice],
            gap,
            if (overview.hasNothing)
              QaEmptyState(
                illustration: QaIllustrationKind.sensor,
                title: l10n.forecast_emptyTitle,
                message: l10n.forecast_emptyMessage,
                actionLabel: l10n.home_pickAnother,
                onAction: () => unawaited(showSedePicker(context)),
                compact: true,
              )
            else ...[
              for (var i = 0; i < rows.length; i++)
                Padding(
                  padding: EdgeInsets.only(top: i == 0 ? 0 : QaSpacing.md),
                  child: QaStagger(
                    index: i,
                    child: ForecastRowCard(
                      row: rows[i],
                      isArrival: rows[i].horizon == arrival,
                      onTap: () => unawaited(
                        showForecastDetail(
                          context,
                          row: rows[i],
                          clock: widget.clock,
                        ),
                      ),
                    ),
                  ),
                ),
              gap,
              QaBanner(
                kind: QaBannerKind.note,
                icon: Icons.insights_rounded,
                message: l10n.forecast_note,
              ),
              ..._generated(context, l10n, rows),
            ],
          ],
        );
      },
    );
  }

  /// Cuándo se generaron los pronósticos vigentes (el más viejo manda), con su
  /// antigüedad.
  List<Widget> _generated(
    BuildContext context,
    AppLocalizations l10n,
    List<ForecastRow> rows,
  ) {
    ForecastRow? oldest;
    for (final row in rows) {
      if (!row.isCurrent || row.generatedAt == null) continue;
      if (oldest == null || row.generatedAt!.isBefore(oldest.generatedAt!)) {
        oldest = row;
      }
    }
    final at = oldest?.generatedAt;
    final age = oldest?.age(widget.clock);
    if (at == null || age == null) return const [];
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    return [
      const SizedBox(height: QaSpacing.lg),
      Text(
        l10n.forecast_generatedAt(
          _time.formatTime(at, locale),
          lotAgeText(l10n, age),
        ),
        style: theme.textTheme.bodySmall?.copyWith(
          color: context.qaColors.onSurfaceMuted,
        ),
        textAlign: TextAlign.center,
      ),
    ];
  }

  static Duration _since(Duration elapsed) =>
      elapsed.isNegative ? Duration.zero : elapsed;

  /// La tarjeta de llegada y los cuatro horizontes en carga.
  Widget _skeleton(AppLocalizations l10n) {
    return QaLoadingRegion(
      semanticLabel: l10n.forecast_loading,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: AlignmentDirectional.centerStart,
            child: QaSkeleton(width: 140, height: 36),
          ),
          const SizedBox(height: QaSpacing.lg),
          const QaSkeleton(height: 96, borderRadius: QaRadii.cardRadius),
          for (var i = 0; i < 4; i++) ...[
            const SizedBox(height: QaSpacing.md),
            const QaCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  QaSkeleton(width: 110, height: 18),
                  SizedBox(height: QaSpacing.sm),
                  QaSkeleton(height: 8),
                  SizedBox(height: QaSpacing.sm),
                  QaSkeleton(width: 140, height: 14),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

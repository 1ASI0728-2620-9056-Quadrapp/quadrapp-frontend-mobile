// US04, US05, US07, US09 a US15, US36
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quadrapp_mobile/composition/arrival/arrival_cubit.dart';
import 'package:quadrapp_mobile/composition/arrival/arrival_hero_card.dart';
import 'package:quadrapp_mobile/composition/arrival/arrival_state.dart';
import 'package:quadrapp_mobile/composition/arrival/home_greeting.dart';
import 'package:quadrapp_mobile/composition/arrival/horizons_card.dart';
import 'package:quadrapp_mobile/composition/eta/eta_cubit.dart';
import 'package:quadrapp_mobile/composition/eta/eta_sheet.dart';
import 'package:quadrapp_mobile/composition/sede/live_status.dart';
import 'package:quadrapp_mobile/composition/sede/sede_chip.dart';
import 'package:quadrapp_mobile/composition/sede/sede_cubit.dart';
import 'package:quadrapp_mobile/composition/sede/sede_no_data_card.dart';
import 'package:quadrapp_mobile/composition/sede/sede_prompt.dart';
import 'package:quadrapp_mobile/composition/sede/sede_state.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';
import 'package:quadrapp_mobile/core/time/app_time_formatter.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';
import 'package:quadrapp_mobile/core/time/countdown.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

Stream<void> _everySecond() =>
    Stream<void>.periodic(const Duration(seconds: 1));

/// Inicio, «Tu llegada» (`/home`): ¿encontraré espacio al llegar? El estado de
/// la conexión en vivo, la tarjeta de petróleo con la categoría y la
/// probabilidad, y «Cómo puede cambiar» a 15, 30, 45 y 60 minutos.
///
/// Cinco estados (docs/05): skeleton al cargar, vacío (la institución sin
/// sedes), error recuperable, parcial o desactualizado (aviso de lo que falta,
/// de datos vencidos o de sin conexión) y éxito. Deslizar hacia abajo recarga.
/// Sin sede elegida, pide elegirla.
///
/// La antigüedad ("Updated 20 s ago") se recalcula cada segundo con la hora del
/// servidor más el tiempo transcurrido (reloj monótono), nunca con el reloj del
/// teléfono: [clock] y [ticker] se inyectan.
class HomePage extends StatefulWidget {
  const HomePage({
    required this.clock,
    required this.tabIndex,
    required this.onOpenAccount,
    required this.onOpenForecast,
    this.fullName,
    this.ticker = _everySecond,
    super.key,
  });

  final Clock clock;

  /// Posición de esta pestaña en la barra (para subir al inicio al volver a
  /// tocarla).
  final int tabIndex;

  /// El nombre completo de la sesión; sin él se saluda sin nombre.
  final String? fullName;
  final Ticker ticker;

  /// El perfil de la barra superior lleva a la cuenta.
  final VoidCallback onOpenAccount;

  /// Las fichas de «Cómo puede cambiar» llevan a la predicción.
  final VoidCallback onOpenForecast;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const AppTimeFormatter _time = AppTimeFormatter();

  final ScrollController _scroll = ScrollController();
  StreamSubscription<void>? _ticks;

  @override
  void initState() {
    super.initState();
    _ticks = widget.ticker().listen((_) {
      if (mounted) setState(() {});
    });
    // La sede y el ETA que ya estén listos (al volver a esta pestaña).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncLot(context.read<SedeCubit>().state);
      unawaited(
        context.read<ArrivalCubit>().setEta(
          context.read<EtaCubit>().state.estimate?.minutes.value,
        ),
      );
    });
  }

  @override
  void dispose() {
    unawaited(_ticks?.cancel());
    _scroll.dispose();
    super.dispose();
  }

  void _syncLot(ViewState<SedeSelection> state) {
    final selected = state is ViewData<SedeSelection>
        ? state.data.selected
        : null;
    unawaited(context.read<ArrivalCubit>().setLot(selected));
  }

  Future<void> _refresh() async {
    final sede = context.read<SedeCubit>();
    final arrival = context.read<ArrivalCubit>();
    final selected = switch (sede.state) {
      ViewData(:final data) => data.selected,
      _ => null,
    };
    if (selected == null) return sede.load();
    await arrival.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final width = MediaQuery.sizeOf(context).width;
    // Una columna de hasta 480 dp, centrada, con 16 dp a los lados.
    final side = math.max(QaSpacing.screen, (width - 480) / 2);

    return Scaffold(
      body: Column(
        children: [
          QaTopBar(
            title: l10n.title_arrival,
            action: QaTopBarAction(
              icon: Icons.account_circle_outlined,
              label: l10n.account_open,
              onPressed: widget.onOpenAccount,
            ),
          ),
          Expanded(
            child: MultiBlocListener(
              listeners: [
                // Cambió la sede elegida: Inicio carga la nueva.
                BlocListener<SedeCubit, ViewState<SedeSelection>>(
                  listenWhen: (before, after) =>
                      _selectedOf(before)?.id != _selectedOf(after)?.id,
                  listener: (context, state) => _syncLot(state),
                ),
                // Cambió el tiempo de llegada: solo se pide de nuevo la
                // asesoría.
                BlocListener<EtaCubit, EtaState>(
                  listenWhen: (before, after) =>
                      before.estimate?.minutes != after.estimate?.minutes,
                  listener: (context, state) => unawaited(
                    context.read<ArrivalCubit>().setEta(
                      state.estimate?.minutes.value,
                    ),
                  ),
                ),
              ],
              child: QaScrollToTopOnReselect(
                tabIndex: widget.tabIndex,
                controller: _scroll,
                child: RefreshIndicator(
                  onRefresh: _refresh,
                  child: BlocBuilder<SedeCubit, ViewState<SedeSelection>>(
                    builder: (context, sede) => CustomScrollView(
                      controller: _scroll,
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: _slivers(context, l10n, sede, side),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static ParkingLot? _selectedOf(ViewState<SedeSelection> state) =>
      state is ViewData<SedeSelection> ? state.data.selected : null;

  // ------------------------------------------------------------------ cuerpo

  List<Widget> _slivers(
    BuildContext context,
    AppLocalizations l10n,
    ViewState<SedeSelection> sede,
    double side,
  ) {
    Widget padded(Widget child, {double top = QaSpacing.lg}) => SliverPadding(
      padding: EdgeInsets.fromLTRB(side, top, side, 0),
      sliver: SliverToBoxAdapter(child: child),
    );
    Widget fill(Widget child) => SliverFillRemaining(
      hasScrollBody: false,
      child: Center(child: child),
    );

    final selection = switch (sede) {
      ViewData(:final data) => data,
      ViewLoading(:final previous) => previous,
      ViewError(:final previous) => previous,
      _ => null,
    };

    if (selection == null) {
      return switch (sede) {
        ViewEmpty() => [
          fill(
            QaEmptyState(
              illustration: QaIllustrationKind.parking,
              title: l10n.lots_emptyTitle,
              message: l10n.lots_emptyMessage,
            ),
          ),
        ],
        ViewError(:final failure) => [
          fill(
            QaErrorState(
              title: l10n.sede_errorTitle,
              message: loadErrorText(l10n, failure),
              retryLabel: l10n.lots_retry,
              onRetry: () => unawaited(context.read<SedeCubit>().load()),
            ),
          ),
        ],
        _ => [padded(_skeleton(l10n))],
      };
    }
    if (!selection.hasSelection) {
      return [padded(SedePrompt(selection: selection), top: QaSpacing.xl)];
    }

    return [
      padded(
        BlocBuilder<ArrivalCubit, ViewState<ArrivalOverview>>(
          builder: (context, arrival) => _arrivalBody(context, l10n, arrival),
        ),
      ),
      const SliverToBoxAdapter(child: SizedBox(height: QaSpacing.xl)),
    ];
  }

  Widget _arrivalBody(
    BuildContext context,
    AppLocalizations l10n,
    ViewState<ArrivalOverview> arrival,
  ) {
    final arrivalCubit = context.read<ArrivalCubit>();
    return switch (arrival) {
      ViewInitial() ||
      ViewEmpty() ||
      ViewLoading(previous: null) => _skeleton(l10n),
      ViewError(:final failure, previous: null) => Padding(
        padding: const EdgeInsets.only(top: QaSpacing.xxxl),
        child: QaErrorState(
          title: l10n.lots_errorTitle,
          message: loadErrorText(l10n, failure),
          retryLabel: l10n.lots_retry,
          onRetry: () => unawaited(arrivalCubit.load()),
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
          onAction: () => unawaited(arrivalCubit.load()),
        ),
      ),
      ViewLoading(:final previous?) => _content(context, l10n, previous),
      ViewData(:final data) => _content(context, l10n, data),
      ViewPartial(:final data) => _content(context, l10n, data),
    };
  }

  Widget _content(
    BuildContext context,
    AppLocalizations l10n,
    ArrivalOverview overview, {
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
    final period = greetingPeriodFor(
      _time.toLima(widget.clock.now()).hour,
    );
    final greeting = l10n.home_greeting(period.name);
    final name = firstNameOf(widget.fullName);

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
      if (overview.isPartial && !overview.hasNoData)
        if (overview.occupancy == null)
          QaBanner(
            kind: QaBannerKind.error,
            message: l10n.home_partialOccupancy,
          )
        else if (overview.adviceStatus == AdviceStatus.unavailable)
          QaBanner(kind: QaBannerKind.error, message: l10n.home_partialAdvice)
        else
          QaBanner(kind: QaBannerKind.note, message: l10n.home_partialForecast),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: QaSpacing.md,
          runSpacing: QaSpacing.sm,
          children: [const SedeChip(), ?live],
        ),
        const SizedBox(height: QaSpacing.lg),
        Text(
          name == null ? greeting : l10n.home_greetingNamed(greeting, name),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceMuted,
          ),
        ),
        const SizedBox(height: QaSpacing.xs),
        Semantics(
          header: true,
          child: Text(
            l10n.home_question,
            style: theme.textTheme.headlineSmall,
          ),
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
          QaStagger(
            index: 0,
            child: BlocBuilder<EtaCubit, EtaState>(
              builder: (context, eta) => ArrivalHeroCard(
                overview: overview,
                eta: eta,
                clock: widget.clock,
                onChangeEta: () => unawaited(showEtaSheet(context)),
              ),
            ),
          ),
          if (overview.horizons.isNotEmpty) ...[
            const SizedBox(height: QaSpacing.lg),
            QaStagger(
              index: 1,
              child: HorizonsCard(
                horizons: overview.horizons,
                onOpenForecast: widget.onOpenForecast,
              ),
            ),
          ],
        ],
        const SizedBox(height: QaSpacing.lg),
        const _PrivacyLine(),
      ],
    );
  }

  /// La sede, el saludo, el héroe y las fichas en carga: bloques grises con la
  /// misma disposición que el contenido real.
  Widget _skeleton(AppLocalizations l10n) {
    return QaLoadingRegion(
      semanticLabel: l10n.lots_loading,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          QaSkeleton(width: 140, height: 36),
          SizedBox(height: QaSpacing.lg),
          QaSkeleton(width: 120, height: 14),
          SizedBox(height: QaSpacing.sm),
          QaSkeleton(width: 240, height: 24),
          SizedBox(height: QaSpacing.lg),
          _SkeletonHero(),
          SizedBox(height: QaSpacing.lg),
          _SkeletonTiles(),
        ],
      ),
    );
  }
}

class _SkeletonHero extends StatelessWidget {
  const _SkeletonHero();

  @override
  Widget build(BuildContext context) {
    return const QaCard(
      padding: EdgeInsets.all(QaSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          QaSkeleton(width: 170, height: 32),
          SizedBox(height: QaSpacing.xl),
          QaSkeleton(height: 28),
          SizedBox(height: QaSpacing.sm),
          QaSkeleton(width: 200, height: 28),
          SizedBox(height: QaSpacing.xl),
          QaSkeleton(height: 56),
        ],
      ),
    );
  }
}

class _SkeletonTiles extends StatelessWidget {
  const _SkeletonTiles();

  @override
  Widget build(BuildContext context) {
    return const QaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          QaSkeleton(width: 140, height: 18),
          SizedBox(height: QaSpacing.md),
          Row(
            children: [
              Expanded(child: QaSkeleton(height: 56)),
              SizedBox(width: QaSpacing.sm),
              Expanded(child: QaSkeleton(height: 56)),
              SizedBox(width: QaSpacing.sm),
              Expanded(child: QaSkeleton(height: 56)),
              SizedBox(width: QaSpacing.sm),
              Expanded(child: QaSkeleton(height: 56)),
            ],
          ),
        ],
      ),
    );
  }
}

/// La nota de privacidad: sin el tráfico en vivo, «Compartimos minutos de
/// llegada, nunca tu ubicación»; con él, dice que la ubicación aproximada va a
/// Google (nunca a Quadrapp).
class _PrivacyLine extends StatelessWidget {
  const _PrivacyLine();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;
    return BlocBuilder<EtaCubit, EtaState>(
      buildWhen: (before, after) => before.usesTraffic != after.usesTraffic,
      builder: (context, eta) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Icon(
              Icons.verified_user_outlined,
              size: 18,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: QaSpacing.sm),
          Expanded(
            child: Text(
              eta.usesTraffic
                  ? l10n.home_privacyLineTraffic
                  : l10n.home_privacyLine,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

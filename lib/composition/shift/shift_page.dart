// US29, TS17, US20
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quadrapp_mobile/composition/sede/live_status.dart';
import 'package:quadrapp_mobile/composition/sede/sede_chip.dart';
import 'package:quadrapp_mobile/composition/sede/sede_cubit.dart';
import 'package:quadrapp_mobile/composition/sede/sede_gate.dart';
import 'package:quadrapp_mobile/composition/sede/sede_state.dart';
import 'package:quadrapp_mobile/composition/shift/shift_cards.dart';
import 'package:quadrapp_mobile/composition/shift/shift_console.dart';
import 'package:quadrapp_mobile/composition/shift/shift_cubit.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';
import 'package:quadrapp_mobile/core/time/app_time_formatter.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';
import 'package:quadrapp_mobile/core/time/countdown.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

Stream<void> _everySecond() =>
    Stream<void>.periodic(const Duration(seconds: 1));

/// Consola de turno (`/ops/shift`, roles `ADMIN` y `OPERATOR`): el aforo del
/// estacionamiento elegido (libres, ocupados y desconocidos, que nunca cuentan
/// como libres), la saturación prevista, las incidencias de dispositivos y el
/// flujo de entradas y salidas del periodo.
///
/// Cinco estados (docs/05): skeleton al cargar, vacío (sin estacionamientos o
/// sin distribución publicada), error recuperable (incluido el 403 del
/// servidor), parcial o desactualizado (lo que falta se dice en su tarjeta y
/// el dato vencido, en un aviso) y éxito. Deslizar hacia abajo recarga.
///
/// La antigüedad se recalcula cada segundo con la hora del servidor más el
/// tiempo transcurrido (reloj monótono), nunca con el reloj del teléfono.
class ShiftPage extends StatefulWidget {
  const ShiftPage({
    required this.clock,
    required this.tabIndex,
    required this.onOpenDevices,
    required this.onOpenAccount,
    this.ticker = _everySecond,
    super.key,
  });

  final Clock clock;

  /// Posición de la pestaña en la barra inferior.
  final int tabIndex;

  /// «Ver dispositivos» y cada incidencia llevan a Dispositivos.
  final VoidCallback onOpenDevices;

  /// El avatar de la barra superior lleva a la cuenta.
  final VoidCallback onOpenAccount;
  final Ticker ticker;

  @override
  State<ShiftPage> createState() => _ShiftPageState();
}

class _ShiftPageState extends State<ShiftPage> {
  static const AppTimeFormatter _time = AppTimeFormatter();

  StreamSubscription<void>? _ticks;

  @override
  void initState() {
    super.initState();
    _ticks = widget.ticker().listen((_) {
      if (mounted) setState(() {});
    });
    // El estacionamiento que ya esté elegido (al volver a esta pestaña).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _syncLot(context.read<SedeCubit>().state);
    });
  }

  @override
  void dispose() {
    unawaited(_ticks?.cancel());
    super.dispose();
  }

  static ParkingLot? _selectedOf(ViewState<SedeSelection> state) =>
      state is ViewData<SedeSelection> ? state.data.selected : null;

  void _syncLot(ViewState<SedeSelection> state) {
    final lot = _selectedOf(state);
    if (lot != null) unawaited(context.read<ShiftCubit>().load(lot.id));
  }

  Future<void> _refresh() async {
    final sede = context.read<SedeCubit>();
    if (_selectedOf(sede.state) == null) return sede.load();
    await context.read<ShiftCubit>().refresh();
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
        title: l10n.nav_home,
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
                BlocBuilder<ShiftCubit, ViewState<ShiftConsole>>(
                  builder: (context, state) => _body(context, l10n, state),
                ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------ cuerpo

  Widget _body(
    BuildContext context,
    AppLocalizations l10n,
    ViewState<ShiftConsole> state,
  ) {
    final console = switch (state) {
      ViewData(:final data) => data,
      ViewPartial(:final data) => data,
      ViewLoading(:final previous) => previous,
      ViewError(:final previous) => previous,
      _ => null,
    };

    if (console == null) {
      return switch (state) {
        ViewError(:final failure) => _failure(context, l10n, failure),
        _ => _skeleton(l10n),
      };
    }

    final overview = console.overview;
    final locale = Localizations.localeOf(context).languageCode;
    final stale = overview.freshness.isStale(widget.clock);
    final failure = state is ViewError<ShiftConsole> ? state.failure : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(
          context,
          l10n,
          subtitle: _time.formatLongDate(overview.freshness.serverTime, locale),
        ),
        // La recarga falló: se sigue viendo lo último, con el aviso.
        if (failure != null) ...[
          const SizedBox(height: QaSpacing.lg),
          QaBanner(
            kind: QaBannerKind.error,
            message: loadErrorText(l10n, failure),
            actionLabel: l10n.lots_retry,
            onAction: () => unawaited(context.read<ShiftCubit>().refresh()),
          ),
        ],
        if (stale) ...[
          const SizedBox(height: QaSpacing.lg),
          QaBanner(
            kind: QaBannerKind.stale,
            message: l10n.lots_staleSince(
              _time.formatTime(overview.freshness.consolidatedAt, locale),
            ),
          ),
        ],
        const SizedBox(height: QaSpacing.lg),
        ShiftCapacityCard(overview: overview, clock: widget.clock),
        const SizedBox(height: QaSpacing.lg),
        ShiftSaturationCard(overview: overview, clock: widget.clock),
        const SizedBox(height: QaSpacing.lg),
        ShiftAlertsCard(
          console: console,
          clock: widget.clock,
          onOpenDevices: widget.onOpenDevices,
        ),
        const SizedBox(height: QaSpacing.lg),
        ShiftFlowCard(overview: overview),
      ],
    );
  }

  /// La sede, el título de la consola y, si lo hay, la fecha del turno.
  Widget _heading(
    BuildContext context,
    AppLocalizations l10n, {
    String? subtitle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Align(alignment: Alignment.centerLeft, child: SedeChip()),
        const SizedBox(height: QaSpacing.lg),
        QaTabHeader(title: l10n.shift_title, subtitle: subtitle),
      ],
    );
  }

  /// Sin consola que mostrar: el estacionamiento sin distribución publicada
  /// (404) es un estado vacío; el 403 y lo demás, errores recuperables.
  Widget _failure(
    BuildContext context,
    AppLocalizations l10n,
    Failure failure,
  ) {
    void retry() => unawaited(context.read<ShiftCubit>().refresh());
    final content = switch (failure) {
      NotFoundFailure() => QaEmptyState(
        illustration: QaIllustrationKind.parking,
        title: l10n.shift_noLayoutTitle,
        message: l10n.shift_noLayoutMessage,
      ),
      ForbiddenFailure() => QaErrorState(
        title: l10n.shift_errorTitle,
        message: l10n.shift_forbidden,
        retryLabel: l10n.lots_retry,
        onRetry: retry,
      ),
      _ => QaErrorState(
        title: l10n.shift_errorTitle,
        message: loadErrorText(l10n, failure),
        retryLabel: l10n.lots_retry,
        onRetry: retry,
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(context, l10n),
        const SizedBox(height: QaSpacing.xl),
        content,
      ],
    );
  }

  Widget _skeleton(AppLocalizations l10n) {
    return QaLoadingRegion(
      semanticLabel: l10n.shift_loading,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: QaSkeleton(width: 140, height: 36),
          ),
          SizedBox(height: QaSpacing.lg),
          QaSkeleton(width: 220, height: 32),
          SizedBox(height: QaSpacing.sm),
          QaSkeleton.line(width: 160),
          SizedBox(height: QaSpacing.lg),
          QaSkeleton(height: 190, borderRadius: QaRadii.cardRadius),
          SizedBox(height: QaSpacing.lg),
          QaSkeleton(height: 110, borderRadius: QaRadii.cardRadius),
          SizedBox(height: QaSpacing.lg),
          QaSkeleton(height: 150, borderRadius: QaRadii.cardRadius),
        ],
      ),
    );
  }
}

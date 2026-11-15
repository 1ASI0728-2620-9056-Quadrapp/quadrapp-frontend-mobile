// US19, US29
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quadrapp_mobile/composition/accesses/accesses_cards.dart';
import 'package:quadrapp_mobile/composition/accesses/accesses_cubit.dart';
import 'package:quadrapp_mobile/composition/accesses/accesses_overview.dart';
import 'package:quadrapp_mobile/composition/accesses/lot_settings_sheet.dart';
import 'package:quadrapp_mobile/composition/sede/live_status.dart';
import 'package:quadrapp_mobile/composition/sede/sede_chip.dart';
import 'package:quadrapp_mobile/composition/sede/sede_cubit.dart';
import 'package:quadrapp_mobile/composition/sede/sede_gate.dart';
import 'package:quadrapp_mobile/composition/sede/sede_state.dart';
import 'package:quadrapp_mobile/composition/zones/zones_cubit.dart';
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

enum _AccessesTab { flow, settings }

/// Accesos vehiculares (`/ops/accesses`, roles `ADMIN` y `OPERATOR`) del
/// estacionamiento elegido, en dos vistas:
/// - **Flujo en vivo:** entradas y salidas de la ventana con su serie por
///   minuto y la antigüedad del dato, y cada acceso con su estado.
/// - **Configuración:** la configuración propia del estacionamiento (horario,
///   modalidad gratuita y alerta de ocupación) y los accesos registrados con
///   su tipo y si cuentan flujo (US19 esc. 2 y 3). Solo el administrador la
///   edita ([canEditSettings]); el servidor responde 403 igual.
///
/// Cinco estados (docs/05): skeleton al cargar, vacío (sin estacionamientos o
/// sin accesos registrados), error recuperable (incluido el 403), parcial o
/// desactualizado (sin flujo o dato vencido, dicho en su tarjeta y en un
/// aviso) y éxito. Deslizar hacia abajo recarga.
class AccessesPage extends StatefulWidget {
  const AccessesPage({
    required this.clock,
    required this.tabIndex,
    required this.canEditSettings,
    required this.onOpenAccount,
    this.ticker = _everySecond,
    super.key,
  });

  final Clock clock;

  /// Posición de la pestaña en la barra inferior.
  final int tabIndex;

  /// `true` para el administrador de la universidad.
  final bool canEditSettings;

  /// El avatar de la barra superior lleva a la cuenta.
  final VoidCallback onOpenAccount;
  final Ticker ticker;

  @override
  State<AccessesPage> createState() => _AccessesPageState();
}

class _AccessesPageState extends State<AccessesPage> {
  static const AppTimeFormatter _time = AppTimeFormatter();

  StreamSubscription<void>? _ticks;
  _AccessesTab _tab = _AccessesTab.flow;

  @override
  void initState() {
    super.initState();
    _ticks = widget.ticker().listen((_) {
      if (mounted) setState(() {});
    });
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
    if (lot != null) unawaited(context.read<AccessesCubit>().load(lot.id));
  }

  Future<void> _refresh() async {
    final sede = context.read<SedeCubit>();
    if (_selectedOf(sede.state) == null) return sede.load();
    await context.read<AccessesCubit>().refresh();
  }

  Future<void> _editSettings(ParkingLot lot, LotSettings settings) async {
    final cubit = context.read<AccessesCubit>();
    final saved = await showLotSettingsSheet(
      context,
      lotName: lot.name,
      settings: settings,
      onSave: cubit.saveSettings,
    );
    if (!saved || !mounted) return;
    QaHaptics.success();
    showQaSnackbar(
      context,
      message: AppLocalizations.of(context).accesses_saved,
    );
    // El umbral decide cuándo un estacionamiento está «casi lleno»: el
    // selector y Estacionamientos leen el valor nuevo.
    unawaited(context.read<SedeCubit>().load());
    unawaited(context.read<ZonesCubit>().refresh());
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
        title: l10n.nav_accesses,
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
                BlocBuilder<AccessesCubit, ViewState<AccessesOverview>>(
                  builder: (context, state) => _body(context, l10n, lot, state),
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
    ParkingLot lot,
    ViewState<AccessesOverview> state,
  ) {
    final overview = switch (state) {
      ViewData(:final data) => data,
      ViewPartial(:final data) => data,
      ViewLoading(:final previous) => previous,
      ViewError(:final previous) => previous,
      _ => null,
    };

    if (overview == null) {
      return switch (state) {
        ViewError(:final failure) => _failure(context, l10n, lot, failure),
        _ => _skeleton(l10n),
      };
    }

    final locale = Localizations.localeOf(context).languageCode;
    final failure = state is ViewError<AccessesOverview> ? state.failure : null;
    final stale =
        overview.flow != null && overview.freshness.isStale(widget.clock);

    final content = switch (_tab) {
      _AccessesTab.flow => [
        if (stale) ...[
          QaBanner(
            kind: QaBannerKind.stale,
            message: l10n.lots_staleSince(
              _time.formatTime(overview.freshness.consolidatedAt, locale),
            ),
          ),
          const SizedBox(height: QaSpacing.lg),
        ],
        // Sin accesos registrados, su estado vacío lo dice todo.
        if (overview.flow != null ||
            overview.flowUnavailable ||
            overview.accesses.isNotEmpty) ...[
          AccessFlowCard(overview: overview, clock: widget.clock),
          const SizedBox(height: QaSpacing.lg),
        ],
        AccessListCard(accesses: overview.accesses),
      ],
      _AccessesTab.settings => [
        LotSettingsCard(
          settings: overview.settings,
          onEdit: widget.canEditSettings
              ? () => unawaited(_editSettings(lot, overview.settings))
              : null,
        ),
        const SizedBox(height: QaSpacing.lg),
        AccessSetupCard(accesses: overview.accesses),
      ],
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(
          l10n,
          subtitle: l10n.accesses_subtitle(lot.name, overview.accesses.length),
        ),
        // La recarga falló: se sigue viendo lo último, con el aviso.
        if (failure != null) ...[
          const SizedBox(height: QaSpacing.lg),
          QaBanner(
            kind: QaBannerKind.error,
            message: loadErrorText(l10n, failure),
            actionLabel: l10n.lots_retry,
            onAction: () => unawaited(context.read<AccessesCubit>().refresh()),
          ),
        ],
        const SizedBox(height: QaSpacing.lg),
        QaSegmentedToggle<_AccessesTab>(
          segments: [
            QaSegment(value: _AccessesTab.flow, label: l10n.accesses_tabFlow),
            QaSegment(
              value: _AccessesTab.settings,
              label: l10n.accesses_tabSettings,
            ),
          ],
          selected: _tab,
          onChanged: (tab) => setState(() => _tab = tab),
        ),
        const SizedBox(height: QaSpacing.lg),
        ...content,
      ],
    );
  }

  /// La sede, el título y, si lo hay, el subtítulo.
  Widget _heading(AppLocalizations l10n, {String? subtitle}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Align(alignment: Alignment.centerLeft, child: SedeChip()),
        const SizedBox(height: QaSpacing.lg),
        QaTabHeader(title: l10n.accesses_title, subtitle: subtitle),
      ],
    );
  }

  /// Sin accesos que mostrar: el 403 y lo demás son errores recuperables.
  Widget _failure(
    BuildContext context,
    AppLocalizations l10n,
    ParkingLot lot,
    Failure failure,
  ) {
    void retry() => unawaited(context.read<AccessesCubit>().refresh());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(l10n, subtitle: lot.name),
        const SizedBox(height: QaSpacing.xl),
        QaErrorState(
          title: l10n.accesses_errorTitle,
          message: failure is ForbiddenFailure
              ? l10n.accesses_forbidden
              : loadErrorText(l10n, failure),
          retryLabel: l10n.lots_retry,
          onRetry: retry,
        ),
      ],
    );
  }

  Widget _skeleton(AppLocalizations l10n) {
    return QaLoadingRegion(
      semanticLabel: l10n.accesses_loading,
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
          QaSkeleton.line(width: 180),
          SizedBox(height: QaSpacing.lg),
          QaSkeleton(height: 48, borderRadius: QaRadii.cardRadius),
          SizedBox(height: QaSpacing.lg),
          QaSkeleton(height: 230, borderRadius: QaRadii.cardRadius),
          SizedBox(height: QaSpacing.lg),
          QaSkeleton(height: 150, borderRadius: QaRadii.cardRadius),
        ],
      ),
    );
  }
}

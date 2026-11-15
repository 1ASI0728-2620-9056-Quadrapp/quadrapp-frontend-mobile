// US20, US30, US31, US35
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quadrapp_mobile/composition/more/calendar_event_sheet.dart';
import 'package:quadrapp_mobile/composition/more/more_cards.dart';
import 'package:quadrapp_mobile/composition/more/more_cubit.dart';
import 'package:quadrapp_mobile/composition/more/more_overview.dart';
import 'package:quadrapp_mobile/composition/more/tenant_sheets.dart';
import 'package:quadrapp_mobile/composition/sede/live_status.dart';
import 'package:quadrapp_mobile/composition/sede/sede_cubit.dart';
import 'package:quadrapp_mobile/composition/sede/sede_state.dart';
import 'package:quadrapp_mobile/composition/zones/zones_cubit.dart';
import 'package:quadrapp_mobile/composition/zones/zones_sync.dart';
import 'package:quadrapp_mobile/contexts/iam/iam.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';
import 'package:quadrapp_mobile/core/time/app_time_formatter.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

/// Más (`/ops/more`, roles `ADMIN` y `OPERATOR`): la administración de la
/// universidad.
/// - **Dispositivos:** el acceso a la salud del inventario (US20).
/// - **Calendario del campus** (US35): ambos roles registran y cancelan.
/// - **Dominios institucionales** (US30) y **Equipo e invitaciones** (US31):
///   el operador los ve; solo el administrador agrega, retira e invita
///   ([canManage]; el servidor responde 403 igual).
///
/// Cinco estados (docs/05): skeleton, vacío (cada tarjeta dice si no hay
/// entradas, dominios o personas), error recuperable (incluido el 403),
/// parcial (la tarjeta que no llegó lo dice, con un aviso para reintentar) y
/// éxito. Deslizar hacia abajo recarga.
class MorePage extends StatefulWidget {
  const MorePage({
    required this.clock,
    required this.tabIndex,
    required this.canManage,
    required this.session,
    required this.onOpenAccount,
    required this.onOpenDevices,
    super.key,
  });

  final Clock clock;
  final int tabIndex;

  /// `true` para el administrador de la universidad.
  final bool canManage;

  /// La sesión: el nombre de la institución y el correo para marcar «Tú».
  final Session session;
  final VoidCallback onOpenAccount;
  final VoidCallback onOpenDevices;

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  static const AppTimeFormatter _time = AppTimeFormatter();

  bool _allEvents = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(context.read<MoreCubit>().load());
    });
  }

  void _done(String message) {
    QaHaptics.success();
    showQaSnackbar(context, message: message);
  }

  /// Las opciones de alcance: el campus entero, el estacionamiento elegido y
  /// sus zonas.
  List<EventScopeOption> _scopes(AppLocalizations l10n) {
    final sede = context.read<SedeCubit>().state;
    final lot = sede is ViewData<SedeSelection> ? sede.data.selected : null;
    final zones = switch (context.read<ZonesCubit>().state) {
      ViewData(:final data) when data.lot.id == lot?.id => data.layout?.zones,
      ViewPartial(:final data) when data.lot.id == lot?.id =>
        data.layout?.zones,
      _ => null,
    };
    return [
      (lotId: null, zoneId: null, label: l10n.more_wholeCampus),
      if (lot != null) ...[
        (lotId: lot.id, zoneId: null, label: l10n.more_wholeLot(lot.name)),
        for (final zone in zones ?? const <Zone>[])
          (lotId: lot.id, zoneId: zone.id, label: '${lot.name} · ${zone.name}'),
      ],
    ];
  }

  Future<void> _newEvent() async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<MoreCubit>();
    final now = _time.toLima(widget.clock.now());
    final saved = await showNewEventSheet(
      context,
      today: DateTime(now.year, now.month, now.day),
      scopes: _scopes(l10n),
      onSave: cubit.createEvent,
    );
    if (saved && mounted) _done(l10n.more_eventSaved);
  }

  Future<void> _openEvent(CalendarEvent event) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<MoreCubit>();
    final cancelled = await showEventDetailSheet(
      context,
      event: event,
      onCancel: () => cubit.cancelEvent(event.id),
    );
    if (cancelled && mounted) _done(l10n.more_eventCancelled);
  }

  Future<void> _addDomain() async {
    final l10n = AppLocalizations.of(context);
    final added = await showAddDomainSheet(
      context,
      onAdd: context.read<MoreCubit>().addDomain,
    );
    if (added && mounted) _done(l10n.more_domainAdded);
  }

  Future<void> _removeDomain(InstitutionDomain domain) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<MoreCubit>();
    final confirmed = await showQaConfirmDialog(
      context,
      title: l10n.more_removeDomainTitle,
      subject: domain.name.value,
      message: l10n.more_removeDomainMessage,
      confirmLabel: l10n.more_removeDomainConfirm,
      cancelLabel: l10n.layout_cancel,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final failure = await cubit.removeDomain(domain.id);
    if (!mounted) return;
    if (failure == null) {
      _done(l10n.more_domainRemoved);
    } else {
      showQaSnackbar(
        context,
        message: failure is ForbiddenFailure
            ? l10n.more_forbidden
            : failure is NetworkFailure
            ? loadErrorText(l10n, failure)
            : l10n.more_saveError,
      );
    }
  }

  Future<void> _invite() async {
    final l10n = AppLocalizations.of(context);
    final sent = await showInviteSheet(
      context,
      onInvite: context.read<MoreCubit>().invite,
    );
    if (sent && mounted) _done(l10n.more_inviteSent);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Las zonas del estacionamiento elegido son opciones de alcance de un
    // evento.
    return ZonesSync(
      child: QaTabPage(
        tabIndex: widget.tabIndex,
        title: l10n.nav_more,
        action: QaTopBarAction(
          icon: Icons.account_circle_outlined,
          label: l10n.account_open,
          onPressed: widget.onOpenAccount,
        ),
        onRefresh: () => context.read<MoreCubit>().refresh(),
        children: [
          BlocBuilder<MoreCubit, ViewState<MoreOverview>>(
            builder: (context, state) => _body(context, l10n, state),
          ),
        ],
      ),
    );
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l10n,
    ViewState<MoreOverview> state,
  ) {
    final cubit = context.read<MoreCubit>();
    final heading = QaTabHeader(
      title: l10n.more_title,
      subtitle: l10n.more_subtitle(widget.session.institution.name),
    );
    final overview = switch (state) {
      ViewData(:final data) => data,
      ViewPartial(:final data) => data,
      ViewLoading(:final previous) => previous,
      ViewError(:final previous) => previous,
      _ => null,
    };

    if (overview == null) {
      return switch (state) {
        ViewError(:final failure) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            heading,
            const SizedBox(height: QaSpacing.xl),
            QaErrorState(
              title: l10n.more_errorTitle,
              message: failure is ForbiddenFailure
                  ? l10n.more_forbidden
                  : loadErrorText(l10n, failure),
              retryLabel: l10n.lots_retry,
              onRetry: () => unawaited(cubit.refresh()),
            ),
          ],
        ),
        _ => _skeleton(l10n),
      };
    }

    final failure = state is ViewError<MoreOverview> ? state.failure : null;
    final loading = state is ViewLoading<MoreOverview>;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        heading,
        if (failure != null) ...[
          const SizedBox(height: QaSpacing.lg),
          QaBanner(
            kind: QaBannerKind.error,
            message: loadErrorText(l10n, failure),
            actionLabel: l10n.lots_retry,
            onAction: () => unawaited(cubit.refresh()),
          ),
        ] else if (overview.isPartial && !loading) ...[
          const SizedBox(height: QaSpacing.lg),
          QaBanner(
            kind: QaBannerKind.stale,
            message: l10n.more_partial,
            actionLabel: l10n.lots_retry,
            onAction: () => unawaited(cubit.refresh()),
          ),
        ],
        const SizedBox(height: QaSpacing.lg),
        DevicesEntryCard(onOpen: widget.onOpenDevices),
        const SizedBox(height: QaSpacing.lg),
        CalendarCard(
          events: overview.events,
          limit: _allEvents ? null : 4,
          onShowAll: () => setState(() => _allEvents = true),
          onAdd: () => unawaited(_newEvent()),
          onOpen: (event) => unawaited(_openEvent(event)),
        ),
        const SizedBox(height: QaSpacing.lg),
        DomainsCard(
          domains: overview.domains,
          onAdd: widget.canManage ? () => unawaited(_addDomain()) : null,
          onRemove: widget.canManage
              ? (domain) => unawaited(_removeDomain(domain))
              : null,
        ),
        const SizedBox(height: QaSpacing.lg),
        TeamCard(
          team: overview.team,
          currentEmail: widget.session.email.value,
          onInvite: widget.canManage ? () => unawaited(_invite()) : null,
        ),
      ],
    );
  }

  Widget _skeleton(AppLocalizations l10n) {
    return QaLoadingRegion(
      semanticLabel: l10n.more_loading,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          QaSkeleton(width: 120, height: 32),
          SizedBox(height: QaSpacing.sm),
          QaSkeleton.line(width: 220),
          SizedBox(height: QaSpacing.lg),
          QaSkeleton(height: 72, borderRadius: QaRadii.cardRadius),
          SizedBox(height: QaSpacing.lg),
          QaSkeleton(height: 260, borderRadius: QaRadii.cardRadius),
          SizedBox(height: QaSpacing.lg),
          QaSkeleton(height: 180, borderRadius: QaRadii.cardRadius),
        ],
      ),
    );
  }
}

// US23, US24, US33
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quadrapp_mobile/composition/alerts/alert_format.dart';
import 'package:quadrapp_mobile/composition/alerts/alerts_cubit.dart';
import 'package:quadrapp_mobile/composition/alerts/alerts_state.dart';
import 'package:quadrapp_mobile/composition/alerts/subscription_card.dart';
import 'package:quadrapp_mobile/composition/alerts/subscription_sheet.dart';
import 'package:quadrapp_mobile/composition/sede/live_status.dart';
import 'package:quadrapp_mobile/composition/sede/sede_cubit.dart';
import 'package:quadrapp_mobile/composition/sede/sede_state.dart';
import 'package:quadrapp_mobile/contexts/notifications/notifications.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

/// Alertas y preferencias (`/alerts`): el interruptor de las notificaciones,
/// «Avísame cuando» (saturación prevista, disponibilidad baja para tu hora de
/// llegada, datos desactualizados, cambios por eventos), las franjas que sigue
/// el conductor (agregar, pausar, eliminar), cómo se comporta la app sin
/// conexión y la nota de privacidad.
///
/// Cinco estados (docs/05): skeleton al cargar, vacío (aún no sigue ninguna
/// franja), error recuperable, parcial (falta una de las dos partes) y éxito.
/// Los interruptores cambian al instante; si el servidor no los guarda, vuelven
/// atrás y un aviso lo dice. Deslizar hacia abajo recarga.
class AlertsTabPage extends StatefulWidget {
  const AlertsTabPage({required this.tabIndex, super.key});

  /// Posición de la pestaña en la barra inferior.
  final int tabIndex;

  @override
  State<AlertsTabPage> createState() => _AlertsTabPageState();
}

class _AlertsTabPageState extends State<AlertsTabPage> {
  StreamSubscription<AlertsNotice>? _notices;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<AlertsCubit>();
    _notices = cubit.notices.listen(_showNotice);
    unawaited(cubit.load());
  }

  @override
  void dispose() {
    unawaited(_notices?.cancel());
    super.dispose();
  }

  void _showNotice(AlertsNotice notice) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    final (message, ok) = switch (notice) {
      AlertsNotice.permissionDenied => (
        l10n.alerts_noticePermissionDenied,
        false,
      ),
      AlertsNotice.permissionBlocked => (
        l10n.alerts_noticePermissionBlocked,
        false,
      ),
      AlertsNotice.activationFailed => (
        l10n.alerts_noticeActivationFailed,
        false,
      ),
      AlertsNotice.saveFailed => (l10n.alerts_noticeSaveFailed, false),
      AlertsNotice.slotFailed => (l10n.alerts_noticeSlotFailed, false),
      AlertsNotice.slotDuplicate => (l10n.alerts_noticeSlotDuplicate, false),
      AlertsNotice.deleteFailed => (l10n.alerts_noticeDeleteFailed, false),
      AlertsNotice.deleted => (l10n.alerts_noticeDeleted, true),
      AlertsNotice.created => (l10n.alerts_noticeCreated, true),
      AlertsNotice.createdDenied => (l10n.alerts_noticeCreatedDenied, true),
      AlertsNotice.createdBlocked => (l10n.alerts_noticeCreatedBlocked, true),
      AlertsNotice.createdNoDevice => (l10n.alerts_noticeCreatedNoDevice, true),
    };
    showQaSnackbar(
      context,
      message: message,
      icon: ok ? Icons.check_circle_outline : Icons.error_outline_rounded,
    );
  }

  List<ParkingLot> _lots(ViewState<SedeSelection> state) =>
      state is ViewData<SedeSelection> ? state.data.lots : const [];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sede = context.watch<SedeCubit>().state;
    final lots = _lots(sede);
    return QaTabPage(
      tabIndex: widget.tabIndex,
      title: l10n.title_alerts,
      onRefresh: () => context.read<AlertsCubit>().refresh(),
      children: [
        BlocBuilder<AlertsCubit, ViewState<AlertsOverview>>(
          builder: (context, state) => switch (state) {
            ViewInitial() ||
            ViewEmpty() ||
            ViewLoading(previous: null) => _skeleton(l10n),
            ViewError(:final failure, previous: null) => Padding(
              padding: const EdgeInsets.only(top: QaSpacing.xxxl),
              child: QaErrorState(
                title: l10n.alerts_errorTitle,
                message: loadErrorText(l10n, failure),
                retryLabel: l10n.lots_retry,
                onRetry: () => unawaited(context.read<AlertsCubit>().load()),
              ),
            ),
            ViewError(:final failure, :final previous?) => _content(
              context,
              l10n,
              previous,
              lots,
              sede,
              error: QaBanner(
                kind: QaBannerKind.error,
                message: loadErrorText(l10n, failure),
                actionLabel: l10n.lots_retry,
                onAction: () => unawaited(context.read<AlertsCubit>().load()),
              ),
            ),
            ViewLoading(:final previous?) => _content(
              context,
              l10n,
              previous,
              lots,
              sede,
            ),
            ViewData(:final data) => _content(context, l10n, data, lots, sede),
            ViewPartial(:final data) => _content(
              context,
              l10n,
              data,
              lots,
              sede,
            ),
          },
        ),
      ],
    );
  }

  Widget _content(
    BuildContext context,
    AppLocalizations l10n,
    AlertsOverview overview,
    List<ParkingLot> lots,
    ViewState<SedeSelection> sede, {
    QaBanner? error,
  }) {
    const gap = SizedBox(height: QaSpacing.lg);
    final cubit = context.read<AlertsCubit>();
    final preferences = overview.preferences;
    final subscriptions = overview.subscriptions;
    final selected = sede is ViewData<SedeSelection>
        ? sede.data.selected
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (error != null) ...[error, gap],
        if (preferences == null)
          QaBanner(
            kind: QaBannerKind.error,
            message: l10n.alerts_partialPreferences,
            actionLabel: l10n.lots_retry,
            onAction: () => unawaited(cubit.load()),
          )
        else
          ..._preferences(l10n, cubit, preferences),
        gap,
        if (subscriptions == null)
          QaBanner(
            kind: QaBannerKind.error,
            message: l10n.alerts_partialSlots,
            actionLabel: l10n.lots_retry,
            onAction: () => unawaited(cubit.load()),
          )
        else
          ..._slots(context, l10n, subscriptions, lots, selected),
        gap,
        _ConnectivityCard(),
        gap,
        QaBanner(
          kind: QaBannerKind.info,
          icon: Icons.verified_user_outlined,
          message: l10n.alerts_privacy,
        ),
      ],
    );
  }

  // ------------------------------------------------------------ preferencias

  List<Widget> _preferences(
    AppLocalizations l10n,
    AlertsCubit cubit,
    NotificationPreferences preferences,
  ) {
    final theme = Theme.of(context);
    final colors = context.qaColors;
    final on = preferences.pushEnabled;

    Widget row(
      AlertPreference kind,
      IconData icon,
      String title,
      String help,
    ) => QaSwitchRow(
      icon: icon,
      title: title,
      help: help,
      value: preferenceValue(preferences, kind),
      onChanged: on
          ? (value) => unawaited(cubit.setPreference(kind, value: value))
          : null,
    );

    return [
      QaCard(
        padding: const EdgeInsets.symmetric(
          horizontal: QaSpacing.lg,
          vertical: QaSpacing.sm,
        ),
        child: QaSwitchRow(
          icon: Icons.notifications_active_outlined,
          title: l10n.alerts_pushTitle,
          help: on ? l10n.alerts_pushOn : l10n.alerts_pushOff,
          value: on,
          onChanged: (value) => unawaited(cubit.setPushEnabled(enabled: value)),
        ),
      ),
      const SizedBox(height: QaSpacing.lg),
      QaCard(
        padding: const EdgeInsets.fromLTRB(
          QaSpacing.lg,
          QaSpacing.lg,
          QaSpacing.lg,
          QaSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.alerts_sectionWhen.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceMuted,
                  letterSpacing: 0.6,
                ),
              ),
            ),
            const SizedBox(height: QaSpacing.xs),
            row(
              AlertPreference.saturation,
              Icons.trending_up_rounded,
              l10n.alerts_saturationTitle,
              l10n.alerts_saturationHelp,
            ),
            const Divider(height: 1),
            row(
              AlertPreference.lowArrival,
              Icons.warning_amber_rounded,
              l10n.alerts_lowArrivalTitle,
              l10n.alerts_lowArrivalHelp,
            ),
            const Divider(height: 1),
            row(
              AlertPreference.staleData,
              Icons.wifi_off_rounded,
              l10n.alerts_staleTitle,
              l10n.alerts_staleHelp,
            ),
            const Divider(height: 1),
            row(
              AlertPreference.events,
              Icons.event_available_outlined,
              l10n.alerts_eventsTitle,
              l10n.alerts_eventsHelp,
            ),
            if (!on) ...[
              const SizedBox(height: QaSpacing.sm),
              Text(
                l10n.alerts_whenOffHint,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceMuted,
                ),
              ),
              const SizedBox(height: QaSpacing.sm),
            ],
          ],
        ),
      ),
    ];
  }

  // ----------------------------------------------------------------- franjas

  List<Widget> _slots(
    BuildContext context,
    AppLocalizations l10n,
    List<AlertSubscription> subscriptions,
    List<ParkingLot> lots,
    ParkingLot? selected,
  ) {
    final theme = Theme.of(context);
    final cubit = context.read<AlertsCubit>();
    final locale = Localizations.localeOf(context).languageCode;
    String lotName(AlertSubscription sub) {
      for (final lot in lots) {
        if (lot.id == sub.lotId) return lot.name;
      }
      return '#${sub.lotId.value}';
    }

    Future<void> confirmDelete(AlertSubscription sub) async {
      final confirmed = await showQaConfirmDialog(
        context,
        title: l10n.alerts_deleteTitle,
        subject: l10n.alerts_deleteSubject(
          lotName(sub),
          daysLabel(sub.days, locale),
          slotLabel(sub.slot, locale),
        ),
        message: l10n.alerts_deleteMessage,
        confirmLabel: l10n.alerts_deleteConfirm,
        cancelLabel: l10n.alerts_deleteCancel,
        icon: Icons.delete_outline_rounded,
        destructive: true,
      );
      if (confirmed) unawaited(cubit.removeSubscription(sub));
    }

    void add() => unawaited(
      showSubscriptionSheet(context, lots: lots, initialLot: selected),
    );

    final colors = context.qaColors;
    final header = Semantics(
      header: true,
      child: Text(
        l10n.alerts_slotsTitle.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: colors.onSurfaceMuted,
          letterSpacing: 0.6,
        ),
      ),
    );

    if (subscriptions.isEmpty) {
      return [
        header,
        const SizedBox(height: QaSpacing.md),
        QaEmptyState(
          illustration: QaIllustrationKind.sensor,
          title: l10n.alerts_slotsEmptyTitle,
          message: l10n.alerts_slotsEmptyMessage,
          actionLabel: lots.isEmpty ? null : l10n.alerts_addSlot,
          onAction: lots.isEmpty ? null : add,
          compact: true,
        ),
      ];
    }

    // Una sola tarjeta con encabezado y filas divididas, como «Avísame
    // cuando»; la acción de agregar cierra la lista.
    return [
      QaCard(
        padding: const EdgeInsets.fromLTRB(
          QaSpacing.lg,
          QaSpacing.lg,
          QaSpacing.lg,
          QaSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            for (var i = 0; i < subscriptions.length; i++) ...[
              if (i > 0) const Divider(height: 1),
              SubscriptionCard(
                subscription: subscriptions[i],
                lotName: lotName(subscriptions[i]),
                onActiveChanged: (active) => unawaited(
                  cubit.setSubscriptionActive(subscriptions[i], active: active),
                ),
                onDelete: () => unawaited(confirmDelete(subscriptions[i])),
              ),
            ],
            const Divider(height: 1),
            const SizedBox(height: QaSpacing.xs),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: QaButton(
                label: l10n.alerts_addSlot,
                icon: Icons.add_circle_outline_rounded,
                variant: QaButtonVariant.text,
                onPressed: lots.isEmpty ? null : add,
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _skeleton(AppLocalizations l10n) {
    return QaLoadingRegion(
      semanticLabel: l10n.alerts_loading,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          QaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                QaSkeleton(width: 120, height: 14),
                SizedBox(height: QaSpacing.md),
                QaSkeleton(height: 44),
                SizedBox(height: QaSpacing.md),
                QaSkeleton(height: 44),
                SizedBox(height: QaSpacing.md),
                QaSkeleton(height: 44),
              ],
            ),
          ),
          SizedBox(height: QaSpacing.lg),
          QaCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                QaSkeleton(width: 140, height: 18),
                SizedBox(height: QaSpacing.md),
                QaSkeleton(height: 44),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// «Conectividad intermitente · Automático»: lo que hace la app sin conexión.
/// Es informativa: no hay nada que elegir.
class _ConnectivityCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;
    return QaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: QaSpacing.md,
            runSpacing: QaSpacing.sm,
            children: [
              Text(
                l10n.alerts_connectivityTitle,
                style: theme.textTheme.titleSmall,
              ),
              DecoratedBox(
                decoration: ShapeDecoration(
                  color: colors.primaryContainer,
                  shape: const StadiumBorder(),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: QaSpacing.lg,
                    vertical: QaSpacing.sm,
                  ),
                  child: Text(
                    l10n.alerts_connectivityValue,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.onPrimaryContainer,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: QaSpacing.sm),
          Text(
            l10n.alerts_connectivityHelp,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}

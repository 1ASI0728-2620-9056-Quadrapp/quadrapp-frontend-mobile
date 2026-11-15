// US20, TS10
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quadrapp_mobile/composition/devices/devices_cards.dart';
import 'package:quadrapp_mobile/composition/devices/devices_cubit.dart';
import 'package:quadrapp_mobile/composition/devices/report_problem_sheet.dart';
import 'package:quadrapp_mobile/composition/sede/live_status.dart';
import 'package:quadrapp_mobile/composition/sede/sede_chip.dart';
import 'package:quadrapp_mobile/composition/sede/sede_cubit.dart';
import 'package:quadrapp_mobile/composition/sede/sede_gate.dart';
import 'package:quadrapp_mobile/composition/sede/sede_state.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/parking_sensing.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';
import 'package:quadrapp_mobile/core/time/countdown.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

Stream<void> _everySecond() =>
    Stream<void>.periodic(const Duration(seconds: 1));

enum _DevicesTab { incidents, sensors, gateways }

/// Filtro de la lista de sensores.
enum _SensorFilter { all, attention, operational, decommissioned }

/// Dispositivos (`/ops/more/devices`, roles `ADMIN` y `OPERATOR`) del
/// estacionamiento elegido, en **modo lectura** (US20, TS10): la salud del
/// inventario y, en tres vistas, las incidencias (gateways y sensores que
/// piden atención), los sensores (con buscador y filtro) y los gateways.
/// Registrar, reemplazar y dar de baja es de la plataforma; la universidad
/// **reporta el problema** a soporte.
///
/// Cinco estados (docs/05): skeleton, vacío (sin estacionamientos o sin
/// dispositivos), error recuperable (incluido el 403), desactualizado (la
/// lectura dice su antigüedad) y éxito. Deslizar hacia abajo recarga.
class DevicesPage extends StatefulWidget {
  const DevicesPage({
    required this.clock,
    required this.onBack,
    this.ticker = _everySecond,
    super.key,
  });

  final Clock clock;
  final VoidCallback onBack;
  final Ticker ticker;

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  /// Sensores visibles por tramo en la lista (el resto, con «Mostrar más»).
  static const int _page = 30;

  StreamSubscription<void>? _ticks;
  _DevicesTab _tab = _DevicesTab.incidents;
  _SensorFilter _filter = _SensorFilter.all;
  String _query = '';
  int _visible = _page;

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
    if (lot != null) unawaited(context.read<DevicesCubit>().load(lot.id));
  }

  Future<void> _refresh() async {
    final sede = context.read<SedeCubit>();
    if (_selectedOf(sede.state) == null) return sede.load();
    await context.read<DevicesCubit>().refresh();
  }

  Future<void> _report(List<Device> incidents, [Device? initial]) async {
    final cubit = context.read<DevicesCubit>();
    final sent = await showReportProblemSheet(
      context,
      incidents: incidents,
      initial: initial,
      onSend: cubit.report,
    );
    if (!sent || !mounted) return;
    QaHaptics.success();
    showQaSnackbar(
      context,
      message: AppLocalizations.of(context).devices_reportSent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocListener<SedeCubit, ViewState<SedeSelection>>(
      listenWhen: (before, after) =>
          _selectedOf(before)?.id != _selectedOf(after)?.id,
      listener: (context, state) {
        setState(() {
          _visible = _page;
          _query = '';
        });
        _syncLot(state);
      },
      child: QaTabPage(
        title: l10n.nav_devices,
        onBack: widget.onBack,
        backLabel: l10n.common_back,
        onRefresh: _refresh,
        children: [
          SedeGate(
            skeleton: _skeleton(l10n),
            promptTitle: l10n.shift_promptTitle,
            promptMessage: l10n.shift_promptMessage,
            builder: (context, lot) =>
                BlocBuilder<DevicesCubit, ViewState<DeviceInventory>>(
                  builder: (context, state) => _body(context, l10n, lot, state),
                ),
          ),
        ],
      ),
    );
  }

  Widget _body(
    BuildContext context,
    AppLocalizations l10n,
    ParkingLot lot,
    ViewState<DeviceInventory> state,
  ) {
    final inventory = switch (state) {
      ViewData(:final data) => data,
      ViewLoading(:final previous) => previous,
      ViewError(:final previous) => previous,
      _ => null,
    };
    if (inventory == null || inventory.lotId != lot.id) {
      return switch (state) {
        ViewError(:final failure) => _failure(context, l10n, lot, failure),
        ViewEmpty() => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _heading(l10n, lot),
            const SizedBox(height: QaSpacing.xl),
            QaEmptyState(
              illustration: QaIllustrationKind.sensor,
              title: l10n.devices_emptyTitle,
              message: l10n.devices_emptyMessage,
              actionLabel: l10n.devices_report,
              onAction: () => unawaited(_report(const [])),
            ),
          ],
        ),
        _ => _skeleton(l10n),
      };
    }

    final failure = state is ViewError<DeviceInventory> ? state.failure : null;
    final live = inventory.devices.where((d) => !d.isDecommissioned);
    final attention = [
      for (final d in live)
        if (d.needsAttention) d,
    ];
    final gatewaysDown = [
      for (final d in attention)
        if (d.type == DeviceType.gateway) d,
    ];
    // Primero los que no se comunican; después, por batería.
    final sensorsDown =
        [
          for (final d in attention)
            if (d.type != DeviceType.gateway) d,
        ]..sort((a, b) {
          if (a.status != b.status) {
            return a.status == DeviceStatus.unreachable ? -1 : 1;
          }
          return (a.batteryPct ?? 100).compareTo(b.batteryPct ?? 100);
        });

    final content = switch (_tab) {
      _DevicesTab.incidents => [
        if (attention.isEmpty)
          QaCard(
            child: QaEmptyState(
              compact: true,
              icon: Icons.verified_outlined,
              title: l10n.devices_allGoodTitle,
              message: l10n.devices_allGoodMessage,
            ),
          ),
        for (final gateway in gatewaysDown) ...[
          GatewayIncidentCard(
            inventory: inventory,
            gateway: gateway,
            clock: widget.clock,
            onReport: () => unawaited(_report(attention, gateway)),
          ),
          const SizedBox(height: QaSpacing.lg),
        ],
        if (sensorsDown.isNotEmpty)
          DeviceListCard(
            title: l10n.devices_spotlightTitle(sensorsDown.length),
            inventory: inventory,
            devices: sensorsDown,
            clock: widget.clock,
            limit: 5,
            moreLabel: l10n.devices_seeAllSensors(sensorsDown.length),
            onMore: () => setState(() {
              _tab = _DevicesTab.sensors;
              _filter = _SensorFilter.attention;
            }),
          ),
      ],
      _DevicesTab.sensors => _sensors(l10n, inventory),
      _DevicesTab.gateways => [
        _list(
          l10n,
          inventory,
          [
            for (final d in inventory.devices)
              if (d.type == DeviceType.gateway) d,
          ],
          emptyTitle: l10n.devices_noGateways,
        ),
      ],
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(l10n, lot),
        if (failure != null) ...[
          const SizedBox(height: QaSpacing.lg),
          QaBanner(
            kind: QaBannerKind.error,
            message: loadErrorText(l10n, failure),
            actionLabel: l10n.lots_retry,
            onAction: () => unawaited(context.read<DevicesCubit>().refresh()),
          ),
        ],
        const SizedBox(height: QaSpacing.lg),
        DevicesHealthCard(
          inventory: inventory,
          lotName: lot.name,
          clock: widget.clock,
        ),
        const SizedBox(height: QaSpacing.lg),
        QaSegmentedToggle<_DevicesTab>(
          segments: [
            QaSegment(
              value: _DevicesTab.incidents,
              label: l10n.devices_tabIncidents,
            ),
            QaSegment(
              value: _DevicesTab.sensors,
              label: l10n.devices_tabSensors,
            ),
            QaSegment(
              value: _DevicesTab.gateways,
              label: l10n.devices_tabGateways,
            ),
          ],
          selected: _tab,
          onChanged: (tab) => setState(() => _tab = tab),
        ),
        const SizedBox(height: QaSpacing.lg),
        ...content,
        const SizedBox(height: QaSpacing.lg),
        QaButton(
          label: l10n.devices_report,
          icon: Icons.feedback_outlined,
          expand: true,
          onPressed: () => unawaited(_report(attention)),
        ),
        const SizedBox(height: QaSpacing.sm),
        Text(
          l10n.devices_reportNote,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: context.qaColors.onSurfaceMuted,
          ),
        ),
      ],
    );
  }

  List<Widget> _sensors(AppLocalizations l10n, DeviceInventory inventory) {
    final sensors = inventory
        .where(query: _query)
        .where((d) => d.type != DeviceType.gateway)
        .where(
          (d) => switch (_filter) {
            _SensorFilter.all => true,
            _SensorFilter.attention => d.needsAttention,
            _SensorFilter.operational => d.isOperational,
            _SensorFilter.decommissioned => d.isDecommissioned,
          },
        )
        .toList();
    String filterLabel(_SensorFilter filter) => switch (filter) {
      _SensorFilter.all => l10n.devices_filterAll,
      _SensorFilter.attention => l10n.devices_filterAttention,
      _SensorFilter.operational => l10n.devices_filterOperational,
      _SensorFilter.decommissioned => l10n.devices_filterDecommissioned,
    };
    return [
      QaTextField(
        label: l10n.devices_search,
        hint: l10n.devices_searchHint,
        prefixIcon: Icons.search_rounded,
        textInputAction: TextInputAction.search,
        onChanged: (value) => setState(() {
          _query = value;
          _visible = _page;
        }),
      ),
      const SizedBox(height: QaSpacing.md),
      Wrap(
        spacing: QaSpacing.sm,
        runSpacing: QaSpacing.sm,
        children: [
          for (final filter in _SensorFilter.values)
            ChoiceChip(
              label: Text(filterLabel(filter)),
              selected: _filter == filter,
              onSelected: (_) => setState(() {
                _filter = filter;
                _visible = _page;
              }),
            ),
        ],
      ),
      const SizedBox(height: QaSpacing.md),
      Semantics(
        liveRegion: true,
        child: Text(
          l10n.devices_sensorsShown(sensors.length),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: context.qaColors.onSurfaceMuted,
          ),
        ),
      ),
      const SizedBox(height: QaSpacing.sm),
      _list(
        l10n,
        inventory,
        sensors,
        emptyTitle: l10n.devices_noSensorsMatch,
        limit: _visible,
        onMore: () => setState(() => _visible += _page),
      ),
    ];
  }

  Widget _list(
    AppLocalizations l10n,
    DeviceInventory inventory,
    List<Device> devices, {
    required String emptyTitle,
    int? limit,
    VoidCallback? onMore,
  }) {
    if (devices.isEmpty) {
      return QaCard(
        child: QaEmptyState(
          compact: true,
          icon: Icons.sensors_off_outlined,
          title: emptyTitle,
        ),
      );
    }
    return DeviceListCard(
      inventory: inventory,
      devices: devices,
      clock: widget.clock,
      limit: limit,
      moreLabel: l10n.devices_showMore,
      onMore: onMore,
    );
  }

  Widget _heading(AppLocalizations l10n, ParkingLot lot) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Align(alignment: Alignment.centerLeft, child: SedeChip()),
        const SizedBox(height: QaSpacing.lg),
        QaTabHeader(
          title: l10n.devices_title,
          subtitle: l10n.devices_subtitle(lot.name),
        ),
      ],
    );
  }

  Widget _failure(
    BuildContext context,
    AppLocalizations l10n,
    ParkingLot lot,
    Failure failure,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _heading(l10n, lot),
        const SizedBox(height: QaSpacing.xl),
        QaErrorState(
          title: l10n.devices_errorTitle,
          message: failure is ForbiddenFailure
              ? l10n.devices_forbidden
              : loadErrorText(l10n, failure),
          retryLabel: l10n.lots_retry,
          onRetry: () => unawaited(context.read<DevicesCubit>().refresh()),
        ),
      ],
    );
  }

  Widget _skeleton(AppLocalizations l10n) {
    return QaLoadingRegion(
      semanticLabel: l10n.devices_loading,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: QaSkeleton(width: 140, height: 36),
          ),
          SizedBox(height: QaSpacing.lg),
          QaSkeleton(width: 200, height: 32),
          SizedBox(height: QaSpacing.sm),
          QaSkeleton.line(width: 220),
          SizedBox(height: QaSpacing.lg),
          QaSkeleton(height: 170, borderRadius: QaRadii.cardRadius),
          SizedBox(height: QaSpacing.lg),
          QaSkeleton(height: 48, borderRadius: QaRadii.cardRadius),
          SizedBox(height: QaSpacing.lg),
          QaSkeleton(height: 220, borderRadius: QaRadii.cardRadius),
        ],
      ),
    );
  }
}

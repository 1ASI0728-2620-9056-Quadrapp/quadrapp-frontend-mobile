// US33
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quadrapp_mobile/composition/alerts/alert_format.dart';
import 'package:quadrapp_mobile/composition/alerts/alerts_cubit.dart';
import 'package:quadrapp_mobile/contexts/notifications/notifications.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// «Nueva franja»: la sede, los días y la hora en que suele llegar el
/// conductor (US33 esc. 1). Antes de pedir el permiso de notificaciones lo
/// explica (docs/05, regla 11); el permiso se pide al agregar, no al abrir la
/// ventana. Los errores (franja repetida, hora inválida, sin conexión) se
/// dicen dentro de la ventana, que no se cierra hasta que la franja queda.
Future<void> showSubscriptionSheet(
  BuildContext context, {
  required List<ParkingLot> lots,
  ParkingLot? initialLot,
}) {
  final cubit = context.read<AlertsCubit>();
  final l10n = AppLocalizations.of(context);
  return showQaBottomSheet<void>(
    context,
    builder: (sheetContext) => BlocProvider<AlertsCubit>.value(
      value: cubit,
      child: SubscriptionSheet(
        lots: lots,
        initialLot: initialLot,
        title: l10n.alerts_sheetTitle,
        closeLabel: l10n.alerts_sheetClose,
      ),
    ),
  );
}

/// La ventana de «Nueva franja» (separada de `showSubscriptionSheet` para
/// probarla).
class SubscriptionSheet extends StatefulWidget {
  const SubscriptionSheet({
    required this.lots,
    required this.title,
    required this.closeLabel,
    this.initialLot,
    super.key,
  });

  final List<ParkingLot> lots;
  final ParkingLot? initialLot;
  final String title;
  final String closeLabel;

  @override
  State<SubscriptionSheet> createState() => _SubscriptionSheetState();
}

class _SubscriptionSheetState extends State<SubscriptionSheet> {
  late ParkingLot? _lot = widget.initialLot ?? widget.lots.firstOrNull;
  Set<int> _days = {};
  TimeOfDay? _from;
  TimeOfDay? _to;
  bool _submitting = false;
  String? _error;

  ClockTime? _clock(TimeOfDay? time) => time == null
      ? null
      : ClockTime.create(time.hour, time.minute).valueOrNull;

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final lot = _lot;
    final from = _clock(_from);
    final to = _clock(_to);
    final error = lot == null
        ? l10n.alerts_errorNoLot
        : _days.isEmpty
        ? l10n.alerts_errorDays
        : from == null || to == null
        ? l10n.alerts_errorTimes
        : !from.isBefore(to)
        ? l10n.alerts_errorOrder
        : null;
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _error = null;
      _submitting = true;
    });
    final result = await context.read<AlertsCubit>().createSubscription(
      CreateAlertSubscriptionParams(
        lotId: lot!.id,
        days: _days,
        from: from!,
        to: to!,
      ),
    );
    if (!mounted) return;
    switch (result) {
      case Success():
        Navigator.of(context).pop();
      case Err(:final failure):
        setState(() {
          _submitting = false;
          _error = _errorText(l10n, failure);
        });
    }
  }

  String _errorText(AppLocalizations l10n, Failure failure) =>
      switch (failure) {
        ValidationFailure(:final errors) when errors.containsKey('slot') =>
          l10n.alerts_errorDuplicate,
        ValidationFailure(:final errors) when errors.containsKey('days') =>
          l10n.alerts_errorDays,
        ValidationFailure(:final errors) when errors.containsKey('to') =>
          l10n.alerts_errorOrder,
        ValidationFailure() => l10n.alerts_errorTimes,
        NetworkFailure() => l10n.lots_errorNetwork,
        _ => l10n.lots_errorGeneric,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;
    final locale = Localizations.localeOf(context).languageCode;
    return QaBottomSheet(
      title: widget.title,
      subtitle: l10n.alerts_sheetSubtitle,
      closeLabel: widget.closeLabel,
      footer: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.alerts_sheetPermissionHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: QaSpacing.md),
          QaButton(
            label: l10n.alerts_sheetCreate,
            loadingLabel: l10n.alerts_sheetCreating,
            isLoading: _submitting,
            expand: true,
            onPressed: _submitting ? null : () => unawaited(_submit()),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.alerts_sheetLot,
            style: theme.textTheme.labelMedium?.copyWith(
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: QaSpacing.sm),
          Wrap(
            spacing: QaSpacing.sm,
            runSpacing: QaSpacing.xs,
            children: [
              for (final lot in widget.lots)
                ChoiceChip(
                  label: Text(lot.name),
                  selected: _lot?.id == lot.id,
                  onSelected: _submitting
                      ? null
                      : (_) => setState(() => _lot = lot),
                ),
            ],
          ),
          const SizedBox(height: QaSpacing.lg),
          QaTimeSlotPicker(
            dayLabels: weekdayNames(locale, short: true),
            dayNames: weekdayNames(locale, short: false),
            selectedDays: _days,
            from: _from,
            to: _to,
            daysLabel: l10n.alerts_sheetDays,
            fromLabel: l10n.alerts_sheetFrom,
            toLabel: l10n.alerts_sheetTo,
            pickTimeLabel: l10n.alerts_sheetPickTime,
            onDaysChanged: (days) => setState(() => _days = days),
            onFromChanged: (time) => setState(() => _from = time),
            onToChanged: (time) => setState(() => _to = time),
            errorText: _error,
            enabled: !_submitting,
          ),
        ],
      ),
    );
  }
}

// US35
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quadrapp_mobile/composition/more/calendar_labels.dart';
import 'package:quadrapp_mobile/composition/sede/live_status.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';
import 'package:quadrapp_mobile/core/time/app_time_formatter.dart';

/// A qué afecta la entrada: todo el campus, el estacionamiento elegido o una
/// de sus zonas.
typedef EventScopeOption = ({LotId? lotId, ZoneId? zoneId, String label});

/// Abre «Nuevo evento». [today] es la fecha de hoy en Lima; [scopes], las
/// opciones de alcance (la primera, todo el campus). [onSave] devuelve la
/// falla si no se pudo (la ventana la dice sin cerrarse). Devuelve `true` si
/// se guardó.
Future<bool> showNewEventSheet(
  BuildContext context, {
  required DateTime today,
  required List<EventScopeOption> scopes,
  required Future<Failure?> Function(NewCalendarEvent event) onSave,
}) async {
  final saved = await showQaBottomSheet<bool>(
    context,
    builder: (_) =>
        _NewEventSheet(today: today, scopes: scopes, onSave: onSave),
  );
  return saved ?? false;
}

class _NewEventSheet extends StatefulWidget {
  const _NewEventSheet({
    required this.today,
    required this.scopes,
    required this.onSave,
  });

  final DateTime today;
  final List<EventScopeOption> scopes;
  final Future<Failure?> Function(NewCalendarEvent event) onSave;

  @override
  State<_NewEventSheet> createState() => _NewEventSheetState();
}

class _NewEventSheetState extends State<_NewEventSheet> {
  static const Duration _lima = AppTimeFormatter.limaOffset;

  final TextEditingController _name = TextEditingController();
  CalendarEventType _type = CalendarEventType.campusEvent;
  late DateTime _from = widget.today;
  late DateTime _to = widget.today;
  TimeOfDay _start = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 17, minute: 0);
  late EventScopeOption _scope = widget.scopes.first;
  DemandImpact _impact = DemandImpact.medium;
  Set<CalendarEventError> _errors = const {};
  bool _busy = false;
  Failure? _failure;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  /// Una fecha y hora de Lima como instante UTC.
  static DateTime _instant(DateTime day, [TimeOfDay? time]) => DateTime.utc(
    day.year,
    day.month,
    day.day,
    time?.hour ?? 0,
    time?.minute ?? 0,
  ).subtract(_lima);

  (DateTime, DateTime) get _span => _type.isAcademicPeriod
      // Días completos: hasta la medianoche siguiente al último día.
      ? (
          _instant(_from),
          _instant(DateTime(_to.year, _to.month, _to.day + 1)),
        )
      : (_instant(_from, _start), _instant(_from, _end));

  Future<void> _pickDate({required bool first}) async {
    final today = widget.today;
    final current = first ? _from : _to;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(today.year - 1, today.month, today.day),
      lastDate: DateTime(today.year + 2, today.month, today.day),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (first) {
        _from = picked;
        if (_to.isBefore(_from)) _to = _from;
      } else {
        _to = picked;
      }
    });
  }

  Future<void> _pickTime({required bool start}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start ? _start : _end,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => start ? _start = picked : _end = picked);
  }

  Future<void> _submit() async {
    if (_busy) return;
    final (startsAt, endsAt) = _span;
    final created = NewCalendarEvent.create(
      type: _type,
      name: _name.text,
      impact: _impact,
      startsAt: startsAt,
      endsAt: endsAt,
      lotId: _scope.lotId,
      zoneId: _scope.zoneId,
    );
    final event = created.valueOrNull;
    if (event == null) {
      setState(() {
        _errors = NewCalendarEvent.validate(
          name: _name.text,
          startsAt: startsAt,
          endsAt: endsAt,
          lotId: _scope.lotId,
          zoneId: _scope.zoneId,
        );
        _failure = null;
      });
      return;
    }
    setState(() {
      _errors = const {};
      _failure = null;
      _busy = true;
    });
    final failure = await widget.onSave(event);
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _busy = false;
      _failure = failure;
    });
  }

  String _failureText(AppLocalizations l10n, Failure failure) =>
      switch (failure) {
        ForbiddenFailure() => l10n.more_forbidden,
        ValidationFailure() => l10n.more_eventInvalid,
        NetworkFailure() => loadErrorText(l10n, failure),
        _ => l10n.more_saveError,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;
    final locale = Localizations.localeOf(context).languageCode;
    final failure = _failure;
    final date = DateFormat.yMMMd(locale);
    final labelStyle = theme.textTheme.labelLarge?.copyWith(
      color: colors.onSurface,
      fontWeight: FontWeight.w600,
    );
    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(bottom: QaSpacing.sm),
      child: Semantics(header: true, child: Text(text, style: labelStyle)),
    );
    String? nameError;
    if (_errors.contains(CalendarEventError.nameMissing)) {
      nameError = l10n.more_errorNameMissing;
    } else if (_errors.contains(CalendarEventError.nameTooLong)) {
      nameError = l10n.more_errorNameTooLong(NewCalendarEvent.maxNameLength);
    }
    final timeError = _errors.contains(CalendarEventError.endsBeforeStarts)
        ? l10n.more_errorEndsBefore
        : null;

    return QaBottomSheet(
      title: l10n.more_newEventTitle,
      subtitle: l10n.more_newEventSubtitle,
      closeLabel: l10n.layout_close,
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          QaButton(
            label: l10n.more_saveEvent,
            loadingLabel: l10n.more_saving,
            expand: true,
            isLoading: _busy,
            onPressed: () => unawaited(_submit()),
          ),
          const SizedBox(height: QaSpacing.sm),
          QaButton(
            label: l10n.layout_cancel,
            variant: QaButtonVariant.text,
            expand: true,
            onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (failure != null) ...[
            QaBanner(
              kind: QaBannerKind.error,
              message: _failureText(l10n, failure),
              requestFocus: true,
            ),
            const SizedBox(height: QaSpacing.lg),
          ],
          heading(l10n.more_eventType),
          Wrap(
            spacing: QaSpacing.sm,
            runSpacing: QaSpacing.sm,
            children: [
              for (final type in [
                CalendarEventType.campusEvent,
                CalendarEventType.classes,
                CalendarEventType.exams,
                CalendarEventType.recess,
              ])
                ChoiceChip(
                  label: Text(eventTypeLabel(l10n, type)),
                  selected: _type == type,
                  onSelected: _busy
                      ? null
                      : (_) => setState(() => _type = type),
                ),
            ],
          ),
          const SizedBox(height: QaSpacing.lg),
          QaTextField(
            label: l10n.more_eventName,
            controller: _name,
            hint: l10n.more_eventNameHint,
            errorText: nameError,
            enabled: !_busy,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: QaSpacing.lg),
          if (_type.isAcademicPeriod)
            Row(
              children: [
                Expanded(
                  child: _PickerField(
                    label: l10n.more_eventFrom,
                    value: date.format(_from),
                    icon: Icons.calendar_today_outlined,
                    invalid: timeError != null,
                    onTap: _busy
                        ? null
                        : () => unawaited(_pickDate(first: true)),
                  ),
                ),
                const SizedBox(width: QaSpacing.md),
                Expanded(
                  child: _PickerField(
                    label: l10n.more_eventTo,
                    value: date.format(_to),
                    icon: Icons.calendar_today_outlined,
                    invalid: timeError != null,
                    onTap: _busy
                        ? null
                        : () => unawaited(_pickDate(first: false)),
                  ),
                ),
              ],
            )
          else ...[
            _PickerField(
              label: l10n.more_eventDate,
              value: date.format(_from),
              icon: Icons.calendar_today_outlined,
              onTap: _busy ? null : () => unawaited(_pickDate(first: true)),
            ),
            const SizedBox(height: QaSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _PickerField(
                    label: l10n.more_eventStart,
                    value: _hhmm(_start),
                    icon: Icons.schedule_rounded,
                    invalid: timeError != null,
                    onTap: _busy
                        ? null
                        : () => unawaited(_pickTime(start: true)),
                  ),
                ),
                const SizedBox(width: QaSpacing.md),
                Expanded(
                  child: _PickerField(
                    label: l10n.more_eventEnd,
                    value: _hhmm(_end),
                    icon: Icons.schedule_rounded,
                    invalid: timeError != null,
                    onTap: _busy
                        ? null
                        : () => unawaited(_pickTime(start: false)),
                  ),
                ),
              ],
            ),
          ],
          if (timeError != null) ...[
            const SizedBox(height: QaSpacing.xs),
            Semantics(
              liveRegion: true,
              child: Text(
                timeError,
                style: theme.textTheme.bodySmall?.copyWith(color: colors.full),
              ),
            ),
          ],
          const SizedBox(height: QaSpacing.lg),
          heading(l10n.more_eventScope),
          DropdownButtonFormField<EventScopeOption>(
            initialValue: _scope,
            isExpanded: true,
            decoration: const InputDecoration(),
            items: [
              for (final scope in widget.scopes)
                DropdownMenuItem(
                  value: scope,
                  child: Text(scope.label, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: _busy
                ? null
                : (scope) => setState(() => _scope = scope ?? _scope),
          ),
          const SizedBox(height: QaSpacing.lg),
          heading(l10n.more_eventImpact),
          QaSegmentedToggle<DemandImpact>(
            segments: [
              for (final impact in DemandImpact.values)
                QaSegment(value: impact, label: impactLabel(l10n, impact)),
            ],
            selected: _impact,
            onChanged: _busy ? (_) {} : (i) => setState(() => _impact = i),
          ),
        ],
      ),
    );
  }

  static String _hhmm(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}';
}

/// Un campo que abre un selector (fecha u hora): rótulo arriba, valor e
/// ícono dentro.
class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.invalid = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  final bool invalid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.qaColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: QaSpacing.sm),
        Semantics(
          button: true,
          enabled: onTap != null,
          label: '$label, $value',
          excludeSemantics: true,
          child: Material(
            color: colors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: QaRadii.controlRadius,
              side: BorderSide(
                color: invalid ? colors.full : colors.outline,
                width: invalid ? 2 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 52),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: QaSpacing.md,
                    vertical: QaSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(value, style: theme.textTheme.bodyLarge),
                      ),
                      Icon(icon, size: 20, color: colors.onSurfaceMuted),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Abre el detalle de una entrada con «Cancelar evento» (US35 esc. 3).
/// [onCancel] devuelve la falla si no se pudo. Devuelve `true` si se canceló.
Future<bool> showEventDetailSheet(
  BuildContext context, {
  required CalendarEvent event,
  required Future<Failure?> Function() onCancel,
}) async {
  final cancelled = await showQaBottomSheet<bool>(
    context,
    builder: (_) => _EventDetailSheet(event: event, onCancel: onCancel),
  );
  return cancelled ?? false;
}

class _EventDetailSheet extends StatefulWidget {
  const _EventDetailSheet({required this.event, required this.onCancel});

  final CalendarEvent event;
  final Future<Failure?> Function() onCancel;

  @override
  State<_EventDetailSheet> createState() => _EventDetailSheetState();
}

class _EventDetailSheetState extends State<_EventDetailSheet> {
  bool _busy = false;
  Failure? _failure;

  Future<void> _cancel() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showQaConfirmDialog(
      context,
      title: l10n.more_cancelEventConfirmTitle,
      subject: widget.event.name,
      message: l10n.more_cancelEventConfirmMessage,
      confirmLabel: l10n.more_cancelEvent,
      cancelLabel: l10n.more_keepEvent,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    final failure = await widget.onCancel();
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _busy = false;
      _failure = failure;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;
    final locale = Localizations.localeOf(context).languageCode;
    final event = widget.event;
    final failure = _failure;
    Widget row(IconData icon, String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: QaSpacing.md),
      child: Semantics(
        label: '$label: $value',
        excludeSemantics: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: colors.onSurfaceMuted),
            const SizedBox(width: QaSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceMuted,
                    ),
                  ),
                  Text(value, style: theme.textTheme.bodyLarge),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return QaBottomSheet(
      title: event.name,
      subtitle: eventTypeLabel(l10n, event.type),
      closeLabel: l10n.layout_close,
      footer: QaButton(
        label: l10n.more_cancelEvent,
        loadingLabel: l10n.more_cancelling,
        variant: QaButtonVariant.destructiveOutlined,
        expand: true,
        isLoading: _busy,
        onPressed: () => unawaited(_cancel()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (failure != null) ...[
            QaBanner(
              kind: QaBannerKind.error,
              message: failure is ForbiddenFailure
                  ? l10n.more_forbidden
                  : failure is NetworkFailure
                  ? loadErrorText(l10n, failure)
                  : l10n.more_saveError,
              requestFocus: true,
            ),
            const SizedBox(height: QaSpacing.lg),
          ],
          row(
            Icons.event_outlined,
            l10n.more_eventWhen,
            eventWhen(l10n, event, locale),
          ),
          row(
            Icons.place_outlined,
            l10n.more_eventScope,
            eventScope(l10n, event),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: QaSpacing.md),
            child: Row(
              children: [
                Icon(
                  Icons.trending_up_rounded,
                  size: 20,
                  color: colors.onSurfaceMuted,
                ),
                const SizedBox(width: QaSpacing.md),
                Expanded(
                  child: Text(
                    l10n.more_eventImpact,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                QaStatusChip(
                  tone: impactTone(event.impact),
                  label: impactLabel(l10n, event.impact),
                ),
              ],
            ),
          ),
          QaBanner(kind: QaBannerKind.info, message: l10n.more_cancelEventNote),
        ],
      ),
    );
  }
}

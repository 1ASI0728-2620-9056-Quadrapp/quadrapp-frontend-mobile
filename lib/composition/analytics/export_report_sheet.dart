// US21, US22, US34
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quadrapp_mobile/composition/sede/live_status.dart';
import 'package:quadrapp_mobile/contexts/analytics/analytics.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/time/app_time_formatter.dart';

/// Pide el reporte: [range], [sections] y [format] ya elegidos.
typedef ExportReport =
    Future<Result<ReportDelivery>> Function({
      required AnalyticsRange range,
      required Set<ReportSection> sections,
      required ReportFormat format,
    });

/// Abre «Exportar reporte». [rangeOf] da el rango de 7 o 30 días que termina
/// ahora; [today] es la fecha de hoy en Lima (el límite del calendario).
/// Devuelve a qué correo se envía, o `null` si se cerró sin exportar.
Future<ReportDelivery?> showExportReportSheet(
  BuildContext context, {
  required String lotName,
  required DateTime today,
  required AnalyticsRange Function(AnalyticsPeriod period) rangeOf,
  required ExportReport onExport,
}) {
  return showQaBottomSheet<ReportDelivery>(
    context,
    builder: (_) => _ExportReportSheet(
      lotName: lotName,
      today: today,
      rangeOf: rangeOf,
      onExport: onExport,
    ),
  );
}

enum _Period { days7, days30, custom }

class _ExportReportSheet extends StatefulWidget {
  const _ExportReportSheet({
    required this.lotName,
    required this.today,
    required this.rangeOf,
    required this.onExport,
  });

  final String lotName;
  final DateTime today;
  final AnalyticsRange Function(AnalyticsPeriod period) rangeOf;
  final ExportReport onExport;

  @override
  State<_ExportReportSheet> createState() => _ExportReportSheetState();
}

class _ExportReportSheetState extends State<_ExportReportSheet> {
  _Period _period = _Period.days30;
  DateTimeRange? _custom;
  final Set<ReportSection> _sections = {
    ReportSection.occupancy,
    ReportSection.accuracy,
  };
  ReportFormat _format = ReportFormat.pdf;
  bool _busy = false;
  bool _missingSections = false;
  Failure? _failure;

  Future<void> _choosePeriod(_Period period) async {
    if (period != _Period.custom) {
      setState(() => _period = period);
      return;
    }
    final today = widget.today;
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(today.year - 1, today.month, today.day),
      lastDate: today,
      initialDateRange:
          _custom ??
          DateTimeRange(
            start: DateTime(today.year, today.month, today.day - 13),
            end: today,
          ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _custom = picked;
      _period = _Period.custom;
    });
  }

  AnalyticsRange? get _range => switch (_period) {
    _Period.days7 => widget.rangeOf(AnalyticsPeriod.last7Days),
    _Period.days30 => widget.rangeOf(AnalyticsPeriod.last30Days),
    _Period.custom => switch (_custom) {
      final custom? => AnalyticsRange.days(
        custom.start,
        custom.end,
        utcOffset: AppTimeFormatter.limaOffset,
      ),
      null => null,
    },
  };

  Future<void> _submit() async {
    if (_busy) return;
    if (_sections.isEmpty) {
      setState(() => _missingSections = true);
      return;
    }
    final range = _range;
    if (range == null) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    final result = await widget.onExport(
      range: range,
      sections: Set.of(_sections),
      format: _format,
    );
    if (!mounted) return;
    switch (result) {
      case Success(:final value):
        Navigator.of(context).pop(value);
      case Err(:final failure):
        setState(() {
          _busy = false;
          _failure = failure;
        });
    }
  }

  String _failureText(AppLocalizations l10n, Failure failure) =>
      switch (failure) {
        ForbiddenFailure() => l10n.analytics_exportForbidden,
        ValidationFailure() => l10n.analytics_exportInvalid,
        NetworkFailure() => loadErrorText(l10n, failure),
        _ => l10n.analytics_exportError,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;
    final locale = Localizations.localeOf(context).languageCode;
    final failure = _failure;
    final custom = _custom;
    final labelStyle = theme.textTheme.labelLarge?.copyWith(
      color: colors.onSurface,
      fontWeight: FontWeight.w600,
    );

    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(bottom: QaSpacing.sm),
      child: Semantics(header: true, child: Text(text, style: labelStyle)),
    );

    return QaBottomSheet(
      title: l10n.analytics_exportTitle,
      subtitle: l10n.analytics_exportSubtitle(widget.lotName),
      closeLabel: l10n.layout_close,
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          QaButton(
            label: l10n.analytics_export,
            loadingLabel: l10n.analytics_exporting,
            icon: Icons.download_rounded,
            expand: true,
            isLoading: _busy,
            onPressed: () => unawaited(_submit()),
          ),
          const SizedBox(height: QaSpacing.sm),
          QaButton(
            label: l10n.layout_cancel,
            variant: QaButtonVariant.text,
            expand: true,
            onPressed: _busy ? null : () => Navigator.of(context).pop(),
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
          heading(l10n.analytics_exportPeriod),
          QaSegmentedToggle<_Period>(
            segments: [
              QaSegment(value: _Period.days7, label: l10n.analytics_period7),
              QaSegment(value: _Period.days30, label: l10n.analytics_period30),
              QaSegment(value: _Period.custom, label: l10n.analytics_custom),
            ],
            selected: _period,
            onChanged: _busy ? (_) {} : (p) => unawaited(_choosePeriod(p)),
          ),
          if (_period == _Period.custom && custom != null) ...[
            const SizedBox(height: QaSpacing.sm),
            Text(
              l10n.analytics_customRange(
                DateFormat.yMMMd(locale).format(custom.start),
                DateFormat.yMMMd(locale).format(custom.end),
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceMuted,
              ),
            ),
          ],
          const SizedBox(height: QaSpacing.lg),
          heading(l10n.analytics_exportContent),
          DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: QaRadii.controlRadius,
              border: Border.all(
                color: _missingSections ? colors.full : colors.outline,
                width: _missingSections ? 2 : 1,
              ),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                children: [
                  for (final (i, section) in ReportSection.values.indexed) ...[
                    if (i > 0) Divider(height: 1, color: colors.outline),
                    CheckboxListTile(
                      value: _sections.contains(section),
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(switch (section) {
                        ReportSection.occupancy =>
                          l10n.analytics_sectionOccupancy,
                        ReportSection.accuracy =>
                          l10n.analytics_sectionAccuracy,
                        ReportSection.alerts => l10n.analytics_sectionAlerts,
                      }),
                      onChanged: _busy
                          ? null
                          : (checked) => setState(() {
                              if (checked ?? false) {
                                _sections.add(section);
                                _missingSections = false;
                              } else {
                                _sections.remove(section);
                              }
                            }),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_missingSections) ...[
            const SizedBox(height: QaSpacing.xs),
            Semantics(
              liveRegion: true,
              child: Text(
                l10n.analytics_exportNoContent,
                style: theme.textTheme.bodySmall?.copyWith(color: colors.full),
              ),
            ),
          ],
          const SizedBox(height: QaSpacing.lg),
          heading(l10n.analytics_exportFormat),
          QaSegmentedToggle<ReportFormat>(
            segments: [
              QaSegment(value: ReportFormat.pdf, label: l10n.analytics_pdf),
              QaSegment(value: ReportFormat.csv, label: l10n.analytics_csv),
            ],
            selected: _format,
            onChanged: _busy ? (_) {} : (f) => setState(() => _format = f),
          ),
          const SizedBox(height: QaSpacing.md),
          Text(
            l10n.analytics_exportNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}

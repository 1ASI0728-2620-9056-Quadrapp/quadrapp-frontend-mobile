// US20
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/composition/devices/device_labels.dart';
import 'package:quadrapp_mobile/composition/sede/live_status.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/parking_sensing.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// Envía el reporte con lo elegido.
typedef SendProblemReport =
    Future<Result<ProblemReceipt>> Function({
      required ProblemCategory category,
      DeviceId? deviceId,
      String? detail,
    });

/// Abre «Reportar problema». [incidents] son los dispositivos que piden
/// atención (la incidencia relacionada); [initial] llega preelegido. Devuelve
/// `true` si se envió.
Future<bool> showReportProblemSheet(
  BuildContext context, {
  required List<Device> incidents,
  required SendProblemReport onSend,
  Device? initial,
}) async {
  final sent = await showQaBottomSheet<bool>(
    context,
    builder: (_) => _ReportProblemSheet(
      incidents: incidents,
      initial: initial,
      onSend: onSend,
    ),
  );
  return sent ?? false;
}

/// La categoría que sugiere el estado del dispositivo.
ProblemCategory _suggested(Device? device) => switch (device?.status) {
  DeviceStatus.unreachable => ProblemCategory.noCommunication,
  DeviceStatus.lowBattery => ProblemCategory.lowBattery,
  _ => ProblemCategory.other,
};

class _ReportProblemSheet extends StatefulWidget {
  const _ReportProblemSheet({
    required this.incidents,
    required this.onSend,
    this.initial,
  });

  final List<Device> incidents;
  final Device? initial;
  final SendProblemReport onSend;

  @override
  State<_ReportProblemSheet> createState() => _ReportProblemSheetState();
}

class _ReportProblemSheetState extends State<_ReportProblemSheet> {
  late Device? _device = widget.initial ?? widget.incidents.firstOrNull;
  late ProblemCategory _category = _suggested(_device);
  final TextEditingController _detail = TextEditingController();
  bool _busy = false;
  Failure? _failure;

  @override
  void dispose() {
    _detail.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    final result = await widget.onSend(
      category: _category,
      deviceId: _device?.id,
      detail: _detail.text,
    );
    if (!mounted) return;
    switch (result) {
      case Success():
        Navigator.of(context).pop(true);
      case Err(:final failure):
        setState(() {
          _busy = false;
          _failure = failure;
        });
    }
  }

  String _failureText(AppLocalizations l10n, Failure failure) =>
      switch (failure) {
        ForbiddenFailure() => l10n.devices_reportForbidden,
        ValidationFailure() => l10n.devices_reportInvalid,
        NetworkFailure() => loadErrorText(l10n, failure),
        _ => l10n.devices_reportError,
      };

  String _categoryLabel(AppLocalizations l10n, ProblemCategory category) =>
      switch (category) {
        ProblemCategory.noCommunication => l10n.devices_categoryNoComm,
        ProblemCategory.wrongData => l10n.devices_categoryWrongData,
        ProblemCategory.lowBattery => l10n.devices_categoryLowBattery,
        ProblemCategory.other => l10n.devices_categoryOther,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;
    final failure = _failure;
    final labelStyle = theme.textTheme.labelLarge?.copyWith(
      color: colors.onSurface,
      fontWeight: FontWeight.w600,
    );
    Widget heading(String text) => Padding(
      padding: const EdgeInsets.only(bottom: QaSpacing.sm),
      child: Semantics(header: true, child: Text(text, style: labelStyle)),
    );

    return QaBottomSheet(
      title: l10n.devices_reportTitle,
      subtitle: l10n.devices_reportSubtitle,
      closeLabel: l10n.layout_close,
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          QaButton(
            label: l10n.devices_reportSend,
            loadingLabel: l10n.devices_reportSending,
            icon: Icons.feedback_outlined,
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
          heading(l10n.devices_reportIncident),
          DropdownButtonFormField<Device?>(
            initialValue: _device,
            isExpanded: true,
            decoration: const InputDecoration(),
            items: [
              for (final device in widget.incidents)
                DropdownMenuItem(
                  value: device,
                  child: Text(
                    '${device.hardwareId} · '
                    '${deviceStatusLabel(l10n, device.status)}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              DropdownMenuItem(child: Text(l10n.devices_reportGeneral)),
            ],
            onChanged: _busy
                ? null
                : (device) => setState(() {
                    _device = device;
                    _category = _suggested(device);
                  }),
          ),
          const SizedBox(height: QaSpacing.lg),
          heading(l10n.devices_reportCategory),
          Wrap(
            spacing: QaSpacing.sm,
            runSpacing: QaSpacing.sm,
            children: [
              for (final category in ProblemCategory.values)
                ChoiceChip(
                  label: Text(_categoryLabel(l10n, category)),
                  selected: _category == category,
                  onSelected: _busy
                      ? null
                      : (_) => setState(() => _category = category),
                ),
            ],
          ),
          const SizedBox(height: QaSpacing.lg),
          heading(l10n.devices_reportDetail),
          TextField(
            controller: _detail,
            enabled: !_busy,
            minLines: 3,
            maxLines: 5,
            maxLength: ProblemReport.maxDetailLength,
            textInputAction: TextInputAction.newline,
            decoration: InputDecoration(
              hintText: l10n.devices_reportDetailHint,
              counterText: '',
            ),
          ),
        ],
      ),
    );
  }
}

// US19, US29
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/composition/sede/live_status.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// Abre «Configuración del estacionamiento». [onSave] guarda y devuelve la
/// falla si no se pudo (la ventana sigue abierta y lo dice). Devuelve `true`
/// si se guardó.
Future<bool> showLotSettingsSheet(
  BuildContext context, {
  required String lotName,
  required LotSettings settings,
  required Future<Failure?> Function(LotSettings settings) onSave,
}) async {
  final saved = await showQaBottomSheet<bool>(
    context,
    builder: (_) => _LotSettingsSheet(
      lotName: lotName,
      settings: settings,
      onSave: onSave,
    ),
  );
  return saved ?? false;
}

class _LotSettingsSheet extends StatefulWidget {
  const _LotSettingsSheet({
    required this.lotName,
    required this.settings,
    required this.onSave,
  });

  final String lotName;
  final LotSettings settings;
  final Future<Failure?> Function(LotSettings settings) onSave;

  @override
  State<_LotSettingsSheet> createState() => _LotSettingsSheetState();
}

class _LotSettingsSheetState extends State<_LotSettingsSheet> {
  /// El rango del deslizador (el diseño): por debajo de 50 % la alerta sonaría
  /// casi siempre. Si el valor guardado es menor, el rango lo incluye.
  static const int _sliderMin = 50;

  late LotTime? _opensAt = widget.settings.opensAt;
  late LotTime? _closesAt = widget.settings.closesAt;
  late int _threshold = widget.settings.saturationThresholdPct;
  Set<LotSettingsError> _errors = const {};
  Failure? _failure;
  bool _busy = false;

  int get _min => math.min(_sliderMin, widget.settings.saturationThresholdPct);

  Future<void> _pick(LotTime? current, ValueChanged<LotTime> onPicked) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: current?.hour ?? 8,
        minute: current?.minute ?? 0,
      ),
      // Las horas del estacionamiento van en 24 h, como en el contrato.
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    final time = LotTime.of(picked.hour, picked.minute);
    if (time != null) onPicked(time);
  }

  Future<void> _submit() async {
    if (_busy) return;
    final created = LotSettings.create(
      opensAt: _opensAt,
      closesAt: _closesAt,
      saturationThresholdPct: _threshold,
    );
    final settings = switch (created) {
      Success(:final value) => value,
      Err() => null,
    };
    if (settings == null) {
      setState(() {
        _errors = LotSettings.validate(
          opensAt: _opensAt,
          closesAt: _closesAt,
          saturationThresholdPct: _threshold,
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
    final failure = await widget.onSave(settings);
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
        ForbiddenFailure() => l10n.accesses_saveForbidden,
        ValidationFailure() => l10n.accesses_saveInvalid,
        NetworkFailure() => loadErrorText(l10n, failure),
        _ => l10n.accesses_saveError,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;
    final failure = _failure;

    final scheduleError = _errors.contains(LotSettingsError.scheduleIncomplete)
        ? l10n.accesses_errorSchedule
        : _errors.contains(LotSettingsError.closesBeforeOpens)
        ? l10n.accesses_errorClosesBefore
        : null;
    final labelStyle = theme.textTheme.labelLarge?.copyWith(
      color: colors.onSurface,
      fontWeight: FontWeight.w600,
    );
    final helpStyle = theme.textTheme.bodySmall?.copyWith(
      color: colors.onSurfaceMuted,
    );

    return QaBottomSheet(
      title: l10n.accesses_sheetTitle,
      subtitle: l10n.accesses_sheetSubtitle(widget.lotName),
      closeLabel: l10n.layout_close,
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          QaButton(
            label: l10n.accesses_save,
            loadingLabel: l10n.accesses_saving,
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
          // Horario: apertura y cierre.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _TimeField(
                  label: l10n.accesses_opensAt,
                  value: _opensAt,
                  placeholder: l10n.accesses_pickTime,
                  invalid:
                      scheduleError != null &&
                      (_opensAt == null ||
                          _errors.contains(LotSettingsError.closesBeforeOpens)),
                  onTap: _busy
                      ? null
                      : () => unawaited(
                          _pick(_opensAt, (t) => setState(() => _opensAt = t)),
                        ),
                ),
              ),
              const SizedBox(width: QaSpacing.md),
              Expanded(
                child: _TimeField(
                  label: l10n.accesses_closesAt,
                  value: _closesAt,
                  placeholder: l10n.accesses_pickTime,
                  invalid: scheduleError != null,
                  onTap: _busy
                      ? null
                      : () => unawaited(
                          _pick(
                            _closesAt,
                            (t) => setState(() => _closesAt = t),
                          ),
                        ),
                ),
              ),
            ],
          ),
          if (scheduleError != null) ...[
            const SizedBox(height: QaSpacing.xs),
            Semantics(
              liveRegion: true,
              child: Text(
                scheduleError,
                style: theme.textTheme.bodySmall?.copyWith(color: colors.full),
              ),
            ),
          ],
          const SizedBox(height: QaSpacing.lg),
          // Modalidad: fija, el estacionamiento es gratuito.
          ExcludeSemantics(child: Text(l10n.accesses_mode, style: labelStyle)),
          const SizedBox(height: QaSpacing.sm),
          Semantics(
            label:
                '${l10n.accesses_mode}, ${l10n.accesses_free}. '
                '${l10n.accesses_modeHelp}',
            readOnly: true,
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surfaceMuted,
                    borderRadius: QaRadii.controlRadius,
                    border: Border.all(color: colors.outline),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 52),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: QaSpacing.md,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 20,
                            color: colors.onSurfaceMuted,
                          ),
                          const SizedBox(width: QaSpacing.sm),
                          Text(
                            l10n.accesses_free,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colors.onSurfaceMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: QaSpacing.xs),
                Text(l10n.accesses_modeHelp, style: helpStyle),
              ],
            ),
          ),
          const SizedBox(height: QaSpacing.lg),
          // Alerta de ocupación.
          ExcludeSemantics(
            child: Text(l10n.accesses_threshold, style: labelStyle),
          ),
          const SizedBox(height: QaSpacing.xs),
          ExcludeSemantics(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.accesses_thresholdHelp,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceMuted,
                    ),
                  ),
                ),
                Text(
                  l10n.accesses_percent(_threshold),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Semantics(
            label: '${l10n.accesses_threshold}. ${l10n.accesses_thresholdHelp}',
            child: Slider(
              value: _threshold.toDouble(),
              min: _min.toDouble(),
              max: LotSettings.maxThresholdPct.toDouble(),
              divisions: LotSettings.maxThresholdPct - _min,
              semanticFormatterCallback: (value) =>
                  l10n.accesses_percent(value.round()),
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _threshold = value.round()),
            ),
          ),
          ExcludeSemantics(
            child: Row(
              children: [
                Text(l10n.accesses_percent(_min), style: helpStyle),
                const Spacer(),
                Text(
                  l10n.accesses_percent(LotSettings.maxThresholdPct),
                  style: helpStyle,
                ),
              ],
            ),
          ),
          const SizedBox(height: QaSpacing.xs),
          Text(l10n.accesses_thresholdNote, style: helpStyle),
        ],
      ),
    );
  }
}

/// Una hora como campo de formulario: rótulo arriba, valor y reloj dentro.
class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.placeholder,
    required this.invalid,
    required this.onTap,
  });

  final String label;
  final LotTime? value;
  final String placeholder;
  final bool invalid;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.qaColors;
    final text = value?.hhmm ?? placeholder;
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
          label: '$label, $text',
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
                        child: Text(
                          text,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: value == null
                                ? colors.onSurfaceMuted
                                : colors.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(width: QaSpacing.sm),
                      Icon(
                        Icons.schedule_rounded,
                        size: 20,
                        color: colors.onSurfaceMuted,
                      ),
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

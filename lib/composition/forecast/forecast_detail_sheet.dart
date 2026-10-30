// US09, US10, US11, US12
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/composition/arrival/arrival_copy.dart';
import 'package:quadrapp_mobile/composition/arrival/lot_age_text.dart';
import 'package:quadrapp_mobile/composition/forecast/forecast_state.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/prediction_advisory.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';
import 'package:quadrapp_mobile/core/time/app_time_formatter.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';

/// El detalle de un horizonte de Predicción: la probabilidad de encontrar
/// espacio, la ocupación esperada y, si se supera el umbral de saturación, el
/// momento previsto y su porcentaje (US11), la confianza sin traducirla a una
/// categoría de llegada (US11 esc. 3), cuándo se generó, cuánto tiempo sigue
/// vigente, su origen y, con confianza baja o de contingencia, la advertencia
/// (US12). Un horizonte vencido o faltante lo dice y no se presenta como
/// actual (US10).
Future<void> showForecastDetail(
  BuildContext context, {
  required ForecastRow row,
  required Clock clock,
}) {
  final l10n = AppLocalizations.of(context);
  return showQaBottomSheet<void>(
    context,
    builder: (sheetContext) => QaBottomSheet(
      title: l10n.forecast_detailTitle(row.horizon.minutes),
      closeLabel: l10n.forecast_detailClose,
      child: ForecastDetailBody(row: row, clock: clock),
    ),
  );
}

/// El cuerpo del detalle (separado de la ventana para probarlo).
class ForecastDetailBody extends StatelessWidget {
  const ForecastDetailBody({required this.row, required this.clock, super.key});

  static const AppTimeFormatter _time = AppTimeFormatter();

  final ForecastRow row;
  final Clock clock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;
    final locale = Localizations.localeOf(context).languageCode;
    final forecast = row.forecast;
    final advice = row.currentAdvice;
    final target = row.targetAt;
    final confidence = row.confidence;

    String percentText(double value) => value.toStringAsFixed(0);

    final facts = <(String, String)>[
      if (forecast != null && row.isCurrent) ...[
        (
          l10n.forecast_detailOccupancy,
          '${percentText(forecast.expectedOccupancyPct)}%',
        ),
        (
          l10n.forecast_detailSaturation,
          switch (forecast.saturation) {
            final saturation? => l10n.forecast_detailFillsAt(
              _time.formatTime(saturation.expectedAt, locale),
              percentText(saturation.pct),
            ),
            null => l10n.forecast_detailNoSaturation,
          },
        ),
      ],
      if (forecast != null)
        (
          l10n.forecast_detailGenerated,
          '${_time.formatTime(forecast.generatedAt, locale)} · '
              '${lotAgeText(l10n, forecast.age(clock))}',
        ),
      if (forecast != null)
        (l10n.forecast_detailValid, _validity(l10n, forecast)),
      if (forecast != null && row.isCurrent)
        (
          l10n.forecast_detailSource,
          forecast.isFallback
              ? l10n.forecast_sourceFallback
              : l10n.forecast_sourceModel,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (target != null)
          Text(
            l10n.forecast_detailForTime(_time.formatTime(target, locale)),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceMuted,
            ),
          ),
        if (advice != null) ...[
          const SizedBox(height: QaSpacing.md),
          _Odds(advice: advice),
        ],
        if (!row.isCurrent) ...[
          const SizedBox(height: QaSpacing.md),
          QaBanner(
            kind: QaBannerKind.stale,
            message: row.status == ForecastRowStatus.expired
                ? l10n.forecast_detailExpiredNote
                : l10n.forecast_detailMissingNote,
          ),
        ],
        if (facts.isNotEmpty) ...[
          const SizedBox(height: QaSpacing.lg),
          for (var i = 0; i < facts.length; i++) ...[
            if (i > 0) const Divider(height: 1),
            _Fact(label: facts[i].$1, value: facts[i].$2),
          ],
        ],
        if (confidence != null) ...[
          const SizedBox(height: QaSpacing.lg),
          QaConfidenceMeter(
            level: switch (confidence.level) {
              ConfidenceLevel.low => QaConfidenceLevel.low,
              ConfidenceLevel.medium => QaConfidenceLevel.medium,
              ConfidenceLevel.high => QaConfidenceLevel.high,
            },
            label: l10n.forecast_confidenceLine(
              confidenceLabel(l10n, confidence.level),
            ),
            note: row.isLowConfidence
                ? l10n.forecast_detailLowConfidence
                : null,
          ),
        ],
        if (forecast != null && row.isCurrent) ...[
          const SizedBox(height: QaSpacing.md),
          Text(
            l10n.forecast_detailModel(forecast.modelVersion),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceMuted,
            ),
          ),
        ],
      ],
    );
  }

  String _validity(AppLocalizations l10n, Forecast forecast) {
    final remaining = forecast.validity.remaining(clock);
    if (remaining <= Duration.zero) return l10n.forecast_detailExpired;
    if (remaining.inMinutes < 1) return l10n.forecast_detailValidSoon;
    return l10n.forecast_detailValidMinutes(remaining.inMinutes);
  }
}

/// La probabilidad de encontrar espacio con su categoría.
class _Odds extends StatelessWidget {
  const _Odds({required this.advice});

  final ArrivalAdvice advice;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;
    final category = advice.category!;
    final tone = toneOfCategory(category);
    return Semantics(
      container: true,
      excludeSemantics: true,
      label:
          '${l10n.forecast_detailChance}: '
          '${percentOf(advice.probabilityOfSpace)}%, '
          '${categoryLabel(l10n, category)}',
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: QaSpacing.md,
        runSpacing: QaSpacing.sm,
        children: [
          Text(
            '${percentOf(advice.probabilityOfSpace)}%',
            style: theme.textTheme.displaySmall?.copyWith(
              color: colors.accent(tone),
            ),
          ),
          QaStatusChip(tone: tone, label: categoryLabel(l10n, category)),
          Text(
            l10n.forecast_detailChance,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.qaColors;
    return Semantics(
      container: true,
      excludeSemantics: true,
      label: '$label: $value',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: QaSpacing.md),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: QaSpacing.md,
          runSpacing: QaSpacing.xs,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceMuted,
              ),
            ),
            Text(value, style: theme.textTheme.titleSmall),
          ],
        ),
      ),
    );
  }
}

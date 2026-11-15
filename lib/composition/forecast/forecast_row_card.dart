// US09, US10, US12, US15
import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/composition/arrival/arrival_copy.dart';
import 'package:quadrapp_mobile/composition/forecast/forecast_state.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';
import 'package:quadrapp_mobile/core/time/app_time_formatter.dart';

/// Un horizonte de Predicción: «15 min · 10:05», la probabilidad de encontrar
/// espacio, su barra, la categoría («Buena disponibilidad») y la confianza.
/// La categoría y la confianza van con texto e ícono: nunca solo con el color.
///
/// Un horizonte faltante o vencido no se presenta como pronóstico actual:
/// dice «—» y por qué (US10 esc. 2 y 3). Con [isArrival] la tarjeta es la más
/// cercana al tiempo de llegada y lo dice con una etiqueta y un borde. Toda la
/// tarjeta abre el detalle ([onTap]).
class ForecastRowCard extends StatelessWidget {
  const ForecastRowCard({
    required this.row,
    required this.onTap,
    this.isArrival = false,
    super.key,
  });

  static const AppTimeFormatter _time = AppTimeFormatter();

  final ForecastRow row;
  final bool isArrival;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;
    final locale = Localizations.localeOf(context).languageCode;
    final minutes = row.horizon.minutes;
    final target = row.targetAt;
    final time = target == null ? null : _time.formatTime(target, locale);
    final advice = row.currentAdvice;
    final category = advice?.category;
    final tone = category == null ? null : toneOfCategory(category);
    final percent = advice == null
        ? null
        : percentOf(advice.probabilityOfSpace);
    final confidence = row.confidence;
    final low = row.isLowConfidence;

    final stateText = switch (row.status) {
      ForecastRowStatus.missing => l10n.forecast_rowMissing,
      ForecastRowStatus.expired => l10n.forecast_rowExpired,
      ForecastRowStatus.available =>
        category == null ? l10n.forecast_rowNoOdds : null,
    };
    final categoryText = category == null
        ? null
        : categoryLabel(l10n, category);
    final confidenceText = confidence == null
        ? null
        : l10n.forecast_confidenceLine(confidenceLabel(l10n, confidence.level));
    final tag = isArrival ? l10n.forecast_yourArrivalTag : null;

    final spoken = percent != null
        ? l10n.forecast_rowSpoken(
            minutes,
            time ?? '',
            percent,
            categoryText!,
            confidenceText ?? '',
            tag == null ? '' : ' $tag.',
          )
        : l10n.forecast_rowSpokenOther(
            minutes,
            time ?? '',
            [stateText!, ?confidenceText].join('. '),
            tag == null ? '' : ' $tag.',
          );

    return QaCard(
      onTap: onTap,
      borderColor: isArrival ? colors.primary : null,
      semanticLabel: spoken,
      semanticHint: l10n.forecast_rowHint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: QaSpacing.sm,
                  runSpacing: QaSpacing.xs,
                  children: [
                    Text(
                      l10n.home_minutes(minutes),
                      style: theme.textTheme.titleSmall,
                    ),
                    if (time != null)
                      Text(
                        time,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceMuted,
                        ),
                      ),
                    if (tag != null) _Tag(label: tag),
                  ],
                ),
              ),
              const SizedBox(width: QaSpacing.md),
              Text(
                percent == null ? '—' : '$percent%',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: tone == null
                      ? colors.onSurfaceMuted
                      : colors.accent(tone),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: QaSpacing.sm),
          _Bar(fraction: advice?.probabilityOfSpace, tone: tone),
          const SizedBox(height: QaSpacing.sm),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: QaSpacing.md,
            runSpacing: QaSpacing.xs,
            children: [
              if (categoryText != null)
                Text(
                  categoryText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface,
                  ),
                )
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      row.status == ForecastRowStatus.available
                          ? Icons.help_outline_rounded
                          : Icons.schedule_rounded,
                      size: 14,
                      color: colors.accent(QaTone.unknown),
                    ),
                    const SizedBox(width: QaSpacing.xs),
                    Flexible(
                      child: Text(
                        stateText!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.accent(QaTone.unknown),
                        ),
                      ),
                    ),
                  ],
                ),
              if (confidenceText != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (low) ...[
                      Icon(
                        Icons.info_outline_rounded,
                        size: 14,
                        color: colors.accent(QaTone.unknown),
                      ),
                      const SizedBox(width: QaSpacing.xs),
                    ],
                    Flexible(
                      child: Text(
                        confidenceText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: low
                              ? colors.accent(QaTone.unknown)
                              : colors.onSurfaceMuted,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// La barra de la probabilidad: el relleno del tono de la categoría sobre una
/// pista neutra. Sin probabilidad, solo la pista. Es decorativa: la cifra y la
/// categoría están en texto.
class _Bar extends StatelessWidget {
  const _Bar({required this.fraction, required this.tone});

  final double? fraction;
  final QaTone? tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.qaColors;
    final value = (fraction ?? 0).clamp(0.0, 1.0);
    return ExcludeSemantics(
      child: SizedBox(
        height: 8,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            children: [
              Positioned.fill(child: ColoredBox(color: colors.paint)),
              if (tone != null && value > 0)
                Positioned.fill(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FractionallySizedBox(
                      widthFactor: value,
                      heightFactor: 1,
                      child: ColoredBox(color: colors.graphic(tone!)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// «Tu llegada»: la etiqueta del horizonte más cercano al tiempo de llegada.
class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.qaColors;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: colors.primaryContainer,
        shape: const StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: QaSpacing.sm,
          vertical: 2,
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}

// US21, US22, US34
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:quadrapp_mobile/composition/analytics/analytics_overview.dart';
import 'package:quadrapp_mobile/composition/analytics/occupancy_chart.dart';
import 'package:quadrapp_mobile/contexts/analytics/analytics.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';
import 'package:quadrapp_mobile/core/time/app_time_formatter.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';

const AppTimeFormatter _time = AppTimeFormatter();

/// Un porcentaje redondeado, sin decimales.
int _pct(double value) => value.round();

/// El nombre corto del periodo («hoy», «7 días», «30 días»).
String periodLabel(AppLocalizations l10n, AnalyticsPeriod period) =>
    switch (period) {
      AnalyticsPeriod.today => l10n.analytics_periodToday,
      AnalyticsPeriod.last7Days => l10n.analytics_period7,
      AnalyticsPeriod.last30Days => l10n.analytics_period30,
    };

/// Una franja del día en hora de Lima («10:00–11:30»).
String _window(int startMinute, int endMinute) {
  String hhmm(int minute) =>
      '${(minute ~/ 60).toString().padLeft(2, '0')}:'
      '${(minute % 60).toString().padLeft(2, '0')}';
  return '${hhmm(startMinute)}–${hhmm(endMinute)}';
}

/// Encabezado de tarjeta: título y, a la derecha, una acción opcional.
class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final trailing = this.trailing;
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: QaSpacing.sm),
          trailing,
        ],
      ],
    );
  }
}

/// Una línea con ícono y texto en un tono (nunca solo color).
class _ToneLine extends StatelessWidget {
  const _ToneLine({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: QaSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

// --------------------------------------------------------------- ocupación

/// Ocupación del periodo (US21) con sus horas pico (US22).
///
/// - **Hoy:** por hora, desde las 06:00, con el pronóstico de la próxima hora
///   (punteado) si es todo el estacionamiento y el tramo en que superaría el
///   umbral, con su confianza y hora de generación.
/// - **7 y 30 días:** el promedio de cada día, para comparar días (US22
///   esc. 2).
///
/// Sin registros lo dice (US21 esc. 3); sin datos suficientes para las horas
/// pico, también (US22 esc. 3).
class OccupancyHistoryCard extends StatelessWidget {
  const OccupancyHistoryCard({
    required this.overview,
    required this.lot,
    required this.clock,
    required this.zoneName,
    this.onPickZone,
    super.key,
  });

  final AnalyticsOverview overview;
  final ParkingLot lot;
  final Clock clock;

  /// La zona filtrada; `null` es todo el estacionamiento.
  final String? zoneName;

  /// Abre el filtro de zona; `null` si el estacionamiento no tiene zonas.
  final VoidCallback? onPickZone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.qaColors;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final history = overview.history;
    final scope = zoneName ?? l10n.analytics_wholeLot;
    final onPickZone = this.onPickZone;

    final header = _CardHeader(
      title: l10n.analytics_occupancyTitle(scope),
      trailing: onPickZone == null
          ? null
          : QaButton(
              label: l10n.analytics_filterZone,
              icon: Icons.tune_rounded,
              variant: QaButtonVariant.text,
              onPressed: onPickZone,
            ),
    );

    final Widget body;
    if (history == null) {
      body = _ToneLine(
        icon: Icons.cloud_off_rounded,
        text: l10n.analytics_occupancyUnavailable,
        color: colors.onSurfaceMuted,
      );
    } else if (history.isEmpty) {
      body = QaEmptyState(
        compact: true,
        icon: Icons.query_stats_rounded,
        title: l10n.analytics_noRecordsTitle,
        message: zoneName == null
            ? l10n.analytics_noRecordsMessage
            : l10n.analytics_noRecordsZoneMessage,
      );
    } else {
      body = _chart(context, l10n, history, locale);
    }

    return QaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          const SizedBox(height: QaSpacing.sm),
          body,
          if (history != null && !history.isEmpty) ...[
            const SizedBox(height: QaSpacing.md),
            ..._footer(context, l10n, history, locale),
          ],
          if (history != null) ...[
            const SizedBox(height: QaSpacing.sm),
            Text(
              l10n.analytics_dataUntil(
                _time.formatDateTime(history.serverTime, locale),
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _chart(
    BuildContext context,
    AppLocalizations l10n,
    OccupancyHistory history,
    String locale,
  ) {
    final colors = context.qaColors;
    final hourly = history.granularity == OccupancyGranularity.hour;
    // Por hora, cada punto va a la mitad de su hora.
    final observed = <ChartPoint>[
      for (final point in history.points)
        (
          at: hourly ? point.at.add(const Duration(minutes: 30)) : point.at,
          pct: point.occupancyPct,
        ),
    ];
    final forecasts = overview.currentForecasts(clock);
    final forecast = <ChartPoint>[
      if (forecasts.isNotEmpty) observed.last,
      for (final f in forecasts) (at: f.targetAt, pct: f.expectedOccupancyPct),
    ];
    final risk = overview.risk(
      thresholdPct: lot.saturationThresholdPct,
      clock: clock,
    );

    final DateTime start;
    final DateTime end;
    final List<ChartTick> ticks;
    if (hourly) {
      // Desde las 06:00 (Lima) hasta la última hora con dato o pronóstico, al
      // menos seis horas.
      start = history.range.from.add(const Duration(hours: 6));
      final last = forecast.isNotEmpty ? forecast.last.at : observed.last.at;
      final minEnd = start.add(const Duration(hours: 6));
      final rawEnd = last.isAfter(minEnd) ? last : minEnd;
      end = DateTime.utc(
        rawEnd.year,
        rawEnd.month,
        rawEnd.day,
        rawEnd.hour,
      ).add(Duration(hours: rawEnd.minute == 0 ? 0 : 1));
      final hours = end.difference(start).inHours;
      final step = (hours / 4).ceil().clamp(1, 24);
      ticks = [
        for (var h = 0; h <= hours; h += step)
          (
            at: start.add(Duration(hours: h)),
            label: _time.formatTime(start.add(Duration(hours: h)), locale),
          ),
      ];
    } else {
      start = observed.first.at;
      end = observed.length == 1
          ? start.add(const Duration(days: 1))
          : observed.last.at;
      final n = observed.length;
      final picks = <int>{
        0,
        if (n > 2) (n - 1) ~/ 3,
        if (n > 3) 2 * (n - 1) ~/ 3,
        n - 1,
      };
      ticks = [
        for (final i in picks)
          (
            at: observed[i].at,
            label: _time.formatDayMonth(observed[i].at, locale),
          ),
      ];
    }

    final peak = history.peak!;
    final summary = StringBuffer(
      hourly
          ? l10n.analytics_chartSpokenHourly(
              _pct(history.points.first.occupancyPct),
              _pct(history.latest!.occupancyPct),
              _pct(peak.occupancyPct),
              _time.formatTime(peak.at, locale),
            )
          : l10n.analytics_chartSpokenDaily(
              _pct(history.average!),
              _pct(peak.occupancyPct),
              _time.formatDayMonth(peak.at, locale),
            ),
    );
    if (forecasts.isNotEmpty) {
      final lastForecast = forecasts.last;
      final spoken = l10n.analytics_chartSpokenForecast(
        _pct(lastForecast.expectedOccupancyPct),
        _time.formatTime(lastForecast.targetAt, locale),
      );
      summary.write(' $spoken');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: QaSpacing.lg,
          runSpacing: QaSpacing.xs,
          children: [
            ChartLegendItem(
              label: hourly
                  ? l10n.analytics_legendObserved
                  : l10n.analytics_legendDailyAverage,
              color: colors.ink,
            ),
            if (forecast.isNotEmpty)
              ChartLegendItem(
                label: l10n.analytics_legendForecast,
                color: colors.primary,
                dashed: true,
              ),
            ChartLegendItem(
              label: l10n.analytics_legendThreshold(lot.saturationThresholdPct),
              color: colors.limited,
              dashed: true,
            ),
          ],
        ),
        const SizedBox(height: QaSpacing.md),
        OccupancyChart(
          observed: observed,
          forecast: forecast,
          start: start,
          end: end,
          ticks: ticks,
          thresholdPct: lot.saturationThresholdPct,
          riskFrom: risk?.from,
          riskTo: risk?.to,
          semanticLabel: summary.toString(),
        ),
      ],
    );
  }

  List<Widget> _footer(
    BuildContext context,
    AppLocalizations l10n,
    OccupancyHistory history,
    String locale,
  ) {
    final colors = context.qaColors;
    final lines = <Widget>[];

    // Riesgo previsto (solo hoy, todo el estacionamiento).
    if (overview.showsForecast) {
      final risk = overview.risk(
        thresholdPct: lot.saturationThresholdPct,
        clock: clock,
      );
      if (overview.failures.containsKey(AnalyticsSection.forecast)) {
        lines.add(
          _ToneLine(
            icon: Icons.cloud_off_rounded,
            text: l10n.analytics_forecastUnavailable,
            color: colors.onSurfaceMuted,
          ),
        );
      } else if (risk != null) {
        final from = _time.formatTime(risk.from, locale);
        final to = _time.formatTime(risk.to, locale);
        lines.add(
          _ToneLine(
            icon: Icons.warning_amber_rounded,
            text: l10n.analytics_risk(
              lot.saturationThresholdPct,
              risk.from == risk.to ? from : '$from–$to',
              _pct(risk.confidence.value * 100),
              _time.formatTime(risk.generatedAt, locale),
            ),
            color: colors.limitedText,
          ),
        );
      } else if (overview.currentForecasts(clock).isNotEmpty) {
        lines.add(
          _ToneLine(
            icon: Icons.check_circle_outline_rounded,
            text: l10n.analytics_noRisk(lot.saturationThresholdPct),
            color: colors.free,
          ),
        );
      }
    } else if (history.granularity == OccupancyGranularity.day) {
      final peak = history.peak!;
      lines.add(
        _ToneLine(
          icon: Icons.insights_rounded,
          text: l10n.analytics_dailySummary(
            _pct(history.average!),
            _pct(peak.occupancyPct),
            _time.formatDayMonth(peak.at, locale),
          ),
          color: colors.onSurfaceMuted,
        ),
      );
    }

    // Horas pico (US22).
    final peaks = overview.peaks;
    if (peaks == null) {
      lines.add(
        _ToneLine(
          icon: Icons.cloud_off_rounded,
          text: l10n.analytics_peaksUnavailable,
          color: colors.onSurfaceMuted,
        ),
      );
    } else if (!peaks.sufficientData) {
      lines.add(
        _ToneLine(
          icon: Icons.hourglass_empty_rounded,
          text: l10n.analytics_peaksInsufficient,
          color: colors.onSurfaceMuted,
        ),
      );
    } else {
      final shown = peaks.peaks.take(2).toList();
      if (shown.isNotEmpty) {
        lines.add(
          _ToneLine(
            icon: Icons.schedule_rounded,
            text: l10n.analytics_peaks(
              shown
                  .map(
                    (w) => l10n.analytics_peakWindow(
                      _window(w.startMinute, w.endMinute),
                      _pct(w.avgOccupancyPct),
                    ),
                  )
                  .join(' · '),
            ),
            color: colors.onSurface,
          ),
        );
      }
    }

    return [
      for (var i = 0; i < lines.length; i++) ...[
        if (i > 0) const SizedBox(height: QaSpacing.xs),
        lines[i],
      ],
    ];
  }
}

// ---------------------------------------------------------------- precisión

/// Precisión del pronóstico (US34): el porcentaje global dentro del margen
/// configurado, cada horizonte con su error absoluto medio y, si el periodo
/// tuvo otra versión del modelo, la comparación (esc. 2). Un periodo sin
/// datos suficientes lo dice (esc. 3).
class ForecastAccuracyCard extends StatelessWidget {
  const ForecastAccuracyCard({
    required this.accuracy,
    required this.period,
    super.key,
  });

  /// `null` si no llegó.
  final ForecastAccuracy? accuracy;
  final AnalyticsPeriod period;

  /// Desde aquí, un horizonte se considera confiable.
  static const double goodPct = 80;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.qaColors;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final decimal = NumberFormat('0.0', locale);
    final accuracy = this.accuracy;
    final current = accuracy?.current;

    if (accuracy == null || current == null) {
      return QaCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _CardHeader(title: l10n.analytics_accuracyTitle),
            const SizedBox(height: QaSpacing.md),
            _ToneLine(
              icon: accuracy == null
                  ? Icons.cloud_off_rounded
                  : Icons.hourglass_empty_rounded,
              text: accuracy == null
                  ? l10n.analytics_accuracyUnavailable
                  : l10n.analytics_accuracyNotComputable,
              color: colors.onSurfaceMuted,
            ),
          ],
        ),
      );
    }

    final global = current.withinMarginPct!;
    final previous = accuracy.previous;
    final mae = current.maePoints;
    return QaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CardHeader(title: l10n.analytics_accuracyTitle),
                    const SizedBox(height: QaSpacing.xs),
                    Text(
                      l10n.analytics_accuracySubtitle(
                        periodLabel(l10n, period),
                        current.modelVersion,
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: QaSpacing.md),
              Semantics(
                label: l10n.analytics_globalSpoken(_pct(global)),
                excludeSemantics: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      l10n.accesses_percent(_pct(global)),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      l10n.analytics_global,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: QaSpacing.sm),
          Text(
            l10n.analytics_accuracyHelp,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: QaSpacing.md),
          for (final result in current.results) ...[
            _HorizonRow(result: result, decimal: decimal),
            const SizedBox(height: QaSpacing.md),
          ],
          if (mae != null)
            _ToneLine(
              icon: Icons.straighten_rounded,
              text: l10n.analytics_maeGlobal(decimal.format(mae)),
              color: colors.onSurfaceMuted,
            ),
          if (previous != null && previous.withinMarginPct != null) ...[
            const SizedBox(height: QaSpacing.xs),
            _comparison(l10n, colors, global, previous),
          ],
        ],
      ),
    );
  }

  Widget _comparison(
    AppLocalizations l10n,
    QaColors colors,
    double global,
    ModelAccuracy previous,
  ) {
    final before = previous.withinMarginPct!;
    final diff = _pct(global) - _pct(before);
    final better = diff >= 0;
    return _ToneLine(
      icon: better ? Icons.trending_up_rounded : Icons.trending_down_rounded,
      text: l10n.analytics_previousModel(
        previous.modelVersion,
        _pct(before),
        diff > 0 ? '+$diff' : '$diff',
      ),
      color: better ? colors.free : colors.limitedText,
    );
  }
}

/// Un horizonte: su porcentaje dentro del margen con una barra y su error
/// medio. Bajo el 80 % lleva un ícono de advertencia (no solo el color).
class _HorizonRow extends StatelessWidget {
  const _HorizonRow({required this.result, required this.decimal});

  final AccuracyResult result;
  final NumberFormat decimal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.qaColors;
    final theme = Theme.of(context);
    final within = result.withinMarginPct;
    final mae = result.maePoints;
    final label = l10n.analytics_horizon(result.horizonMinutes);

    if (!result.computable || within == null) {
      return Semantics(
        label: '$label: ${l10n.analytics_horizonNotComputable}',
        excludeSemantics: true,
        child: Row(
          children: [
            Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
            Icon(
              Icons.hourglass_empty_rounded,
              size: 16,
              color: colors.onSurfaceMuted,
            ),
            const SizedBox(width: QaSpacing.xs),
            Text(
              l10n.analytics_horizonNotComputable,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceMuted,
              ),
            ),
          ],
        ),
      );
    }

    final good = within >= ForecastAccuracyCard.goodPct;
    final color = good ? colors.primary : colors.limited;
    final textColor = good ? colors.free : colors.limitedText;
    final maeText = mae == null
        ? null
        : l10n.analytics_mae(decimal.format(mae));
    return Semantics(
      label: [
        l10n.analytics_horizonSpoken(label, _pct(within)),
        ?maeText,
        if (!good) l10n.analytics_belowGood,
      ].join('. '),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
              if (!good) ...[
                Icon(Icons.warning_amber_rounded, size: 16, color: textColor),
                const SizedBox(width: QaSpacing.xs),
              ],
              Text(
                l10n.accesses_percent(_pct(within)),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: QaSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 8,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ColoredBox(color: colors.surfaceMuted),
                  ),
                  FractionallySizedBox(
                    widthFactor: (within / 100).clamp(0, 1),
                    child: ColoredBox(color: color),
                  ),
                ],
              ),
            ),
          ),
          if (maeText != null) ...[
            const SizedBox(height: QaSpacing.xs),
            Text(
              maeText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

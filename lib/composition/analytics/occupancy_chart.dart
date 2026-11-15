// US21, US22

import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';

/// Un punto de la gráfica: un momento y su ocupación (0 a 100).
typedef ChartPoint = ({DateTime at, double pct});

/// Una marca del eje horizontal.
typedef ChartTick = ({DateTime at, String label});

/// La ocupación en el tiempo: la observada como línea continua y el
/// pronóstico como línea punteada (se distinguen por el trazo, no solo por el
/// color), el umbral del estacionamiento como guía y, si se prevé, el tramo
/// de riesgo sombreado.
///
/// Es solo dibujo: para TalkBack se anuncia [semanticLabel], un resumen en
/// palabras de lo que muestra.
class OccupancyChart extends StatelessWidget {
  const OccupancyChart({
    required this.observed,
    required this.start,
    required this.end,
    required this.ticks,
    required this.thresholdPct,
    required this.semanticLabel,
    this.forecast = const [],
    this.riskFrom,
    this.riskTo,
    this.height = 180,
    super.key,
  });

  final List<ChartPoint> observed;

  /// Empieza en el último punto observado, para que las líneas se unan.
  final List<ChartPoint> forecast;
  final DateTime start;
  final DateTime end;
  final List<ChartTick> ticks;
  final int thresholdPct;
  final DateTime? riskFrom;
  final DateTime? riskTo;
  final String semanticLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.qaColors;
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.labelSmall!.copyWith(
      color: colors.onSurfaceMuted,
    );
    final scaler = MediaQuery.textScalerOf(context);
    return Semantics(
      label: semanticLabel,
      image: true,
      excludeSemantics: true,
      child: SizedBox(
        height: height + scaler.scale(14) * 2,
        width: double.infinity,
        child: CustomPaint(
          painter: _ChartPainter(
            observed: observed,
            forecast: forecast,
            start: start,
            end: end,
            ticks: ticks,
            thresholdPct: thresholdPct,
            riskFrom: riskFrom,
            riskTo: riskTo,
            labelStyle: labelStyle,
            textScaler: scaler,
            textDirection: Directionality.of(context),
            lineColor: colors.ink,
            forecastColor: colors.primary,
            gridColor: colors.outline,
            thresholdColor: colors.limited,
            riskColor: colors.limitedFill,
          ),
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.observed,
    required this.forecast,
    required this.start,
    required this.end,
    required this.ticks,
    required this.thresholdPct,
    required this.riskFrom,
    required this.riskTo,
    required this.labelStyle,
    required this.textScaler,
    required this.textDirection,
    required this.lineColor,
    required this.forecastColor,
    required this.gridColor,
    required this.thresholdColor,
    required this.riskColor,
  });

  final List<ChartPoint> observed;
  final List<ChartPoint> forecast;
  final DateTime start;
  final DateTime end;
  final List<ChartTick> ticks;
  final int thresholdPct;
  final DateTime? riskFrom;
  final DateTime? riskTo;
  final TextStyle labelStyle;
  final TextScaler textScaler;
  final TextDirection textDirection;
  final Color lineColor;
  final Color forecastColor;
  final Color gridColor;
  final Color thresholdColor;
  final Color riskColor;

  TextPainter _text(String value) => TextPainter(
    text: TextSpan(text: value, style: labelStyle),
    textDirection: textDirection,
    textScaler: textScaler,
  )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    final yLabels = <int>{0, 50, thresholdPct, 100}.toList()..sort();
    final yPainters = {for (final v in yLabels) v: _text('$v%')};
    final gutter =
        yPainters.values.map((p) => p.width).reduce((a, b) => a > b ? a : b) +
        8;
    final tickHeight = _text('0').height;
    final plot = Rect.fromLTRB(
      gutter,
      tickHeight / 2,
      size.width - 4,
      size.height - tickHeight - 6,
    );
    final span = end.difference(start).inMilliseconds;
    double x(DateTime at) {
      if (span <= 0) return plot.left;
      final t = at.difference(start).inMilliseconds / span;
      return plot.left + plot.width * t.clamp(0, 1);
    }

    double y(double pct) =>
        plot.bottom - plot.height * (pct.clamp(0, 100) / 100);

    // Tramo de riesgo.
    final riskFrom = this.riskFrom;
    final riskTo = this.riskTo;
    if (riskFrom != null && riskTo != null) {
      final left = x(riskFrom);
      final right = x(riskTo);
      canvas.drawRect(
        Rect.fromLTRB(
          left - 6,
          plot.top,
          (right + 6).clamp(0, plot.right),
          plot.bottom,
        ),
        Paint()..color = riskColor,
      );
    }

    // Guías horizontales y sus rótulos.
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (final value in yLabels) {
      final dy = y(value.toDouble());
      if (value == thresholdPct) {
        _dashed(
          canvas,
          Path()
            ..moveTo(plot.left, dy)
            ..lineTo(plot.right, dy),
          Paint()
            ..color = thresholdColor
            ..strokeWidth = 1.5
            ..style = PaintingStyle.stroke,
          dash: 4,
          gap: 4,
        );
      } else {
        canvas.drawLine(Offset(plot.left, dy), Offset(plot.right, dy), grid);
      }
      final label = yPainters[value]!;
      label.paint(canvas, Offset(0, dy - label.height / 2));
    }

    // Marcas del eje horizontal.
    for (final tick in ticks) {
      final label = _text(tick.label);
      final dx = (x(tick.at) - label.width / 2).clamp(
        plot.left - 4,
        size.width - label.width,
      );
      label.paint(canvas, Offset(dx, plot.bottom + 6));
    }

    // Observada: línea continua.
    if (observed.isNotEmpty) {
      final path = Path()..moveTo(x(observed.first.at), y(observed.first.pct));
      for (final point in observed.skip(1)) {
        path.lineTo(x(point.at), y(point.pct));
      }
      final stroke = Paint()
        ..color = lineColor
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, stroke);
      if (observed.length == 1) {
        canvas.drawCircle(
          Offset(x(observed.first.at), y(observed.first.pct)),
          3,
          Paint()..color = lineColor,
        );
      }
    }

    // Pronóstico: línea punteada.
    if (forecast.length > 1) {
      final path = Path()..moveTo(x(forecast.first.at), y(forecast.first.pct));
      for (final point in forecast.skip(1)) {
        path.lineTo(x(point.at), y(point.pct));
      }
      _dashed(
        canvas,
        path,
        Paint()
          ..color = forecastColor
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
        dash: 5,
        gap: 5,
      );
    }
  }

  static void _dashed(
    Canvas canvas,
    Path path,
    Paint paint, {
    required double dash,
    required double gap,
  }) {
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = (distance + dash).clamp(0, metric.length).toDouble();
        canvas.drawPath(metric.extractPath(distance, next), paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.observed != observed ||
      old.forecast != forecast ||
      old.start != start ||
      old.end != end ||
      old.thresholdPct != thresholdPct ||
      old.riskFrom != riskFrom ||
      old.riskTo != riskTo ||
      old.labelStyle != labelStyle ||
      old.textScaler != textScaler ||
      old.lineColor != lineColor;
}

/// La muestra de una serie en la leyenda: un trazo continuo o punteado y su
/// nombre.
class ChartLegendItem extends StatelessWidget {
  const ChartLegendItem({
    required this.label,
    required this.color,
    this.dashed = false,
    super.key,
  });

  final String label;
  final Color color;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final colors = context.qaColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 18,
          height: 4,
          child: dashed
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var i = 0; i < 3; i++)
                      ColoredBox(
                        color: color,
                        child: const SizedBox(width: 4, height: 4),
                      ),
                  ],
                )
              : ColoredBox(color: color),
        ),
        const SizedBox(width: QaSpacing.sm),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceMuted),
        ),
      ],
    );
  }
}

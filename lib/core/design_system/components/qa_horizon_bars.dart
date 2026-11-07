// El campo privado _semanticLabel no puede ser un parámetro inicializador
// con nombre público, y se quiere que el constructor de carga lo exija.
// ignore_for_file: prefer_initializing_formals

import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/core/design_system/components/qa_skeleton.dart';
import 'package:quadrapp_mobile/core/design_system/components/qa_tone_glyph.dart';
import 'package:quadrapp_mobile/core/design_system/painters/qa_hatch.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_colors.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_radii.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_spacing.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_tone.dart';

/// Estado de una barra de horizonte.
enum QaHorizonBarStatus {
  /// Hay pronóstico vigente.
  available,

  /// No hay pronóstico para este horizonte (información parcial).
  missing,

  /// El pronóstico venció y no se muestra como actual.
  expired,
}

/// Datos de una barra (15', 30', 45' o 60').
class QaHorizonBarData {
  const QaHorizonBarData({
    required this.label,
    required this.semanticLabel,
    this.valueLabel,
    this.fraction = 0,
    this.tone = QaTone.unknown,
    this.status = QaHorizonBarStatus.available,
  });

  /// Rótulo bajo la barra, por ejemplo "15 min".
  final String label;

  /// Descripción completa para lectores de pantalla.
  final String semanticLabel;

  /// Cifra sobre la barra, por ejemplo "82 %".
  final String? valueLabel;

  /// Ocupación esperada, de 0 a 1.
  final double fraction;
  final QaTone tone;
  final QaHorizonBarStatus status;
}

/// Ocupación esperada a 15/30/45/60 minutos. Los horizontes faltantes se ven
/// como huecos con contorno discontinuo y los vencidos, con rayado. La
/// saturación prevista ([saturationLabel]) se muestra con su forma y texto.
class QaHorizonBars extends StatelessWidget {
  const QaHorizonBars({
    required this.bars,
    this.saturationLabel,
    super.key,
  }) : _semanticLabel = null;

  const QaHorizonBars.loading({required String semanticLabel, super.key})
    : bars = const [],
      saturationLabel = null,
      _semanticLabel = semanticLabel;

  final List<QaHorizonBarData> bars;

  /// Por ejemplo "Se llena a las 9:20".
  final String? saturationLabel;
  final String? _semanticLabel;

  static const double _trackHeight = 96;

  @override
  Widget build(BuildContext context) {
    final colors = context.qaColors;
    final theme = Theme.of(context);

    if (_semanticLabel != null) {
      return QaLoadingRegion(
        semanticLabel: _semanticLabel,
        child: Row(
          children: [
            for (var i = 0; i < 4; i++) ...[
              if (i > 0) const SizedBox(width: QaSpacing.md),
              const Expanded(
                child: Column(
                  children: [
                    QaSkeleton(height: _trackHeight),
                    SizedBox(height: QaSpacing.sm),
                    QaSkeleton.line(width: 40),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    }

    Widget column(QaHorizonBarData bar) {
      final track = switch (bar.status) {
        QaHorizonBarStatus.available => _FilledTrack(
          fraction: bar.fraction.clamp(0, 1),
          tone: bar.tone,
        ),
        QaHorizonBarStatus.missing => CustomPaint(
          painter: _DashedBoxPainter(color: colors.outline),
          child: const SizedBox.expand(),
        ),
        QaHorizonBarStatus.expired => CustomPaint(
          painter: QaHatchPainter(color: colors.unknown),
          child: const SizedBox.expand(),
        ),
      };
      return Expanded(
        child: Semantics(
          container: true,
          label: bar.semanticLabel,
          child: ExcludeSemantics(
            child: Column(
              children: [
                Text(
                  bar.valueLabel ?? ' ',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: QaSpacing.xs),
                SizedBox(height: _trackHeight, child: track),
                const SizedBox(height: QaSpacing.sm),
                Text(
                  bar.label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < bars.length; i++) ...[
              if (i > 0) const SizedBox(width: QaSpacing.md),
              column(bars[i]),
            ],
          ],
        ),
        if (saturationLabel != null) ...[
          const SizedBox(height: QaSpacing.md),
          Semantics(
            container: true,
            label: saturationLabel,
            child: ExcludeSemantics(
              child: Row(
                children: [
                  const QaToneGlyph(tone: QaTone.full),
                  const SizedBox(width: QaSpacing.sm),
                  Flexible(
                    child: Text(
                      saturationLabel!,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colors.full,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _FilledTrack extends StatelessWidget {
  const _FilledTrack({required this.fraction, required this.tone});

  final double fraction;
  final QaTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.qaColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: QaRadii.controlRadius,
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: FractionallySizedBox(
          heightFactor: fraction,
          widthFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.graphic(tone),
              borderRadius: QaRadii.controlRadius,
              border: Border.all(color: colors.accent(tone), width: 1.5),
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedBoxPainter extends CustomPainter {
  const _DashedBoxPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(0.75),
          const Radius.circular(QaRadii.control),
        ),
      );
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 5), paint);
        distance += 9;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBoxPainter oldDelegate) =>
      oldDelegate.color != color;
}

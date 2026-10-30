// El campo privado _semanticLabel no puede ser un parámetro inicializador
// con nombre público, y se quiere que el constructor de carga lo exija.
// ignore_for_file: prefer_initializing_formals

import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/core/design_system/components/qa_skeleton.dart';
import 'package:quadrapp_mobile/core/design_system/components/qa_tone_glyph.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_colors.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_radii.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_spacing.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_tone.dart';

/// La "placa de llegada": la asesoría con forma de letrero vial, borde interno
/// y la categoría en tipografía grande. Es lo memorable del diseño.
///
/// Estados: éxito (por defecto), cargando ([QaArrivalPlate.loading]) y parcial
/// ([isPartial] con una [note], por ejemplo "Estimación con pocos datos": el
/// borde interno pasa a ser discontinuo). Vacío y error se resuelven con
/// `QaEmptyState` y `QaErrorState` en su lugar.
class QaArrivalPlate extends StatelessWidget {
  const QaArrivalPlate({
    required this.headline,
    required this.categoryLabel,
    required this.tone,
    this.detail,
    this.footnote,
    this.note,
    this.isPartial = false,
    super.key,
  }) : _semanticLabel = null;

  const QaArrivalPlate.loading({required String semanticLabel, super.key})
    : headline = '',
      categoryLabel = '',
      tone = QaTone.unknown,
      detail = null,
      footnote = null,
      note = null,
      isPartial = false,
      _semanticLabel = semanticLabel;

  /// Por ejemplo "Llegas en 18 min".
  final String headline;

  /// Categoría traducida ("Alta"), nunca el código.
  final String categoryLabel;
  final QaTone tone;

  /// Por ejemplo "82 % de probabilidad".
  final String? detail;

  /// Por ejemplo "Confianza media · 8:41".
  final String? footnote;

  /// Aviso dentro de la placa (confianza baja, dato antiguo).
  final String? note;

  /// Dibuja el borde interno discontinuo para marcar una estimación parcial.
  final bool isPartial;

  final String? _semanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.qaColors;
    if (_semanticLabel != null) {
      return QaLoadingRegion(
        semanticLabel: _semanticLabel,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: QaRadii.plateRadius,
            border: Border.all(color: colors.paint),
          ),
          child: const Padding(
            padding: EdgeInsets.all(QaSpacing.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                QaSkeleton.line(width: 140),
                SizedBox(height: QaSpacing.md),
                QaSkeleton(width: 120, height: 48),
                SizedBox(height: QaSpacing.md),
                QaSkeleton.line(width: 180),
                SizedBox(height: QaSpacing.sm),
                QaSkeleton.line(width: 120),
              ],
            ),
          ),
        ),
      );
    }

    final theme = Theme.of(context);
    final background = colors.fill(tone);
    final foreground = colors.onFill(tone);
    final labelParts = [
      headline,
      categoryLabel,
      detail,
      note,
      footnote,
    ].whereType<String>();

    return Semantics(
      container: true,
      label: labelParts.join('. '),
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: QaRadii.plateRadius,
          ),
          child: Padding(
            padding: const EdgeInsets.all(QaSpacing.sm),
            child: CustomPaint(
              foregroundPainter: _InnerBorderPainter(
                color: foreground,
                dashed: isPartial,
              ),
              child: Padding(
                padding: const EdgeInsets.all(QaSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headline,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: foreground,
                      ),
                    ),
                    const SizedBox(height: QaSpacing.xs),
                    Row(
                      children: [
                        QaToneGlyph(tone: tone, size: 24),
                        const SizedBox(width: QaSpacing.md),
                        Flexible(
                          child: Text(
                            categoryLabel,
                            style: theme.textTheme.displayLarge?.copyWith(
                              color: foreground,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (detail != null) ...[
                      const SizedBox(height: QaSpacing.xs),
                      Text(
                        detail!,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: foreground,
                        ),
                      ),
                    ],
                    if (note != null) ...[
                      const SizedBox(height: QaSpacing.sm),
                      Text(
                        note!,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: foreground,
                        ),
                      ),
                    ],
                    if (footnote != null) ...[
                      const SizedBox(height: QaSpacing.sm),
                      Text(
                        footnote!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: foreground,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Borde interno de 2 dp (como el filete de un letrero); discontinuo si la
/// estimación es parcial.
class _InnerBorderPainter extends CustomPainter {
  const _InnerBorderPainter({required this.color, required this.dashed});

  final Color color;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = QaRadii.plateBorderWidth;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          (Offset.zero & size).deflate(QaRadii.plateBorderWidth / 2),
          const Radius.circular(QaRadii.plateInner),
        ),
      );
    if (!dashed) {
      canvas.drawPath(path, paint);
      return;
    }
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + 8), paint);
        distance += 14;
      }
    }
  }

  @override
  bool shouldRepaint(_InnerBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.dashed != dashed;
}

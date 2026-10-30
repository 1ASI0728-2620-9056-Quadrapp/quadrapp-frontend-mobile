import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/core/design_system/painters/qa_hatch.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_colors.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_tone.dart';

/// Forma que acompaña a cada tono, para que el estado nunca dependa solo del
/// color: círculo (libre), triángulo (casi lleno), rombo (lleno o error),
/// cuadrado (ocupado) y cuadrado rayado (sin datos).
class QaToneGlyph extends StatelessWidget {
  const QaToneGlyph({required this.tone, this.size = 14, super.key});

  final QaTone tone;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.qaColors;
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size.square(size),
        painter: _GlyphPainter(
          tone: tone,
          accent: colors.accent(tone),
          fill: colors.graphic(tone),
        ),
      ),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  const _GlyphPainter({
    required this.tone,
    required this.accent,
    required this.fill,
  });

  final QaTone tone;
  final Color accent;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final fillPaint = Paint()..color = fill;
    final strokePaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    switch (tone) {
      case QaTone.free:
        canvas.drawCircle(rect.center, size.width / 2, fillPaint);
      case QaTone.limited:
        final path = Path()
          ..moveTo(rect.center.dx, rect.top + 0.75)
          ..lineTo(rect.right - 0.75, rect.bottom - 0.75)
          ..lineTo(rect.left + 0.75, rect.bottom - 0.75)
          ..close();
        canvas
          ..drawPath(path, fillPaint)
          ..drawPath(path, strokePaint);
      case QaTone.full:
        final path = Path()
          ..moveTo(rect.center.dx, rect.top + 0.5)
          ..lineTo(rect.right - 0.5, rect.center.dy)
          ..lineTo(rect.center.dx, rect.bottom - 0.5)
          ..lineTo(rect.left + 0.5, rect.center.dy)
          ..close();
        canvas.drawPath(path, fillPaint);
      case QaTone.occupied:
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(2)),
          fillPaint,
        );
      case QaTone.unknown:
        final inner = rect.deflate(0.75);
        paintQaHatch(canvas, inner, accent, spacing: 4, strokeWidth: 1.2);
        canvas.drawRRect(
          RRect.fromRectAndRadius(inner, const Radius.circular(2)),
          strokePaint,
        );
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter oldDelegate) =>
      oldDelegate.tone != tone ||
      oldDelegate.accent != accent ||
      oldDelegate.fill != fill;
}

import 'package:flutter/rendering.dart';

/// Dibuja un rayado diagonal a 45° dentro de [rect] (como una zona de no
/// estacionar). Se usa para el estado "sin datos" y para lo vencido.
void paintQaHatch(
  Canvas canvas,
  Rect rect,
  Color color, {
  double spacing = 6,
  double strokeWidth = 1.5,
}) {
  final paint = Paint()
    ..color = color
    ..strokeWidth = strokeWidth
    ..strokeCap = StrokeCap.butt;
  canvas
    ..save()
    ..clipRect(rect);
  for (var d = -rect.height; d < rect.width; d += spacing) {
    canvas.drawLine(
      Offset(rect.left + d, rect.bottom),
      Offset(rect.left + d + rect.height, rect.top),
      paint,
    );
  }
  canvas.restore();
}

/// `CustomPainter` con el rayado de [paintQaHatch].
class QaHatchPainter extends CustomPainter {
  const QaHatchPainter({
    required this.color,
    this.spacing = 6,
    this.strokeWidth = 1.5,
  });

  final Color color;
  final double spacing;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    paintQaHatch(
      canvas,
      Offset.zero & size,
      color,
      spacing: spacing,
      strokeWidth: strokeWidth,
    );
  }

  @override
  bool shouldRepaint(QaHatchPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.spacing != spacing ||
      oldDelegate.strokeWidth != strokeWidth;
}

import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/core/design_system/painters/qa_hatch.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_colors.dart';

/// Barra segmentada libres / ocupados / sin datos de un estacionamiento.
///
/// Cada segmento mide en proporción a su cuenta. Los espacios sin datos van
/// con el rayado diagonal (nunca solo un color) y no cuentan como libres. Es un
/// resumen visual: lleva la misma información en texto (la leyenda y la
/// etiqueta de la tarjeta), así que no expone semántica propia.
class QaOccupancyBar extends StatelessWidget {
  const QaOccupancyBar({
    required this.free,
    required this.occupied,
    required this.unknown,
    super.key,
  });

  final int free;
  final int occupied;
  final int unknown;

  /// Alto de la barra y separación entre segmentos (dp).
  static const double height = 12;
  static const double gap = 2;

  @override
  Widget build(BuildContext context) {
    final colors = context.qaColors;
    return ExcludeSemantics(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: CustomPaint(
          painter: _OccupancyBarPainter(
            free: free,
            occupied: occupied,
            unknown: unknown,
            freeColor: colors.freeGraphic,
            occupiedColor: colors.occupied,
            unknownColor: colors.unknown,
            unknownBackground: colors.surfaceMuted,
          ),
        ),
      ),
    );
  }
}

class _OccupancyBarPainter extends CustomPainter {
  const _OccupancyBarPainter({
    required this.free,
    required this.occupied,
    required this.unknown,
    required this.freeColor,
    required this.occupiedColor,
    required this.unknownColor,
    required this.unknownBackground,
  });

  final int free;
  final int occupied;
  final int unknown;
  final Color freeColor;
  final Color occupiedColor;
  final Color unknownColor;
  final Color unknownBackground;

  @override
  void paint(Canvas canvas, Size size) {
    final total = free + occupied + unknown;
    if (total <= 0) return;
    final segments = [
      (free, freeColor, false),
      (occupied, occupiedColor, false),
      (unknown, unknownColor, true),
    ].where((s) => s.$1 > 0).toList();
    final gaps = (segments.length - 1) * QaOccupancyBar.gap;
    final room = size.width - gaps;
    final radius = Radius.circular(size.height / 2);
    var x = 0.0;
    for (var i = 0; i < segments.length; i++) {
      final (count, color, hatched) = segments[i];
      // Un segmento por pequeño que sea se ve (al menos un poco más que su
      // propio radio), para que "3 sin datos" no desaparezca.
      final width = (room * count / total).clamp(size.height / 2, room);
      final rect = Rect.fromLTWH(x, 0, width, size.height);
      final first = i == 0;
      final last = i == segments.length - 1;
      final shape = RRect.fromRectAndCorners(
        rect,
        topLeft: first ? radius : const Radius.circular(2),
        bottomLeft: first ? radius : const Radius.circular(2),
        topRight: last ? radius : const Radius.circular(2),
        bottomRight: last ? radius : const Radius.circular(2),
      );
      if (hatched) {
        canvas
          ..save()
          ..clipRRect(shape)
          ..drawRect(rect, Paint()..color = unknownBackground);
        paintQaHatch(canvas, rect, color, spacing: 4);
        canvas
          ..restore()
          ..drawRRect(
            shape.deflate(0.75),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5
              ..color = color,
          );
      } else {
        canvas.drawRRect(shape, Paint()..color = color);
      }
      x += width + QaOccupancyBar.gap;
    }
  }

  @override
  bool shouldRepaint(_OccupancyBarPainter old) =>
      old.free != free ||
      old.occupied != occupied ||
      old.unknown != unknown ||
      old.freeColor != freeColor ||
      old.occupiedColor != occupiedColor ||
      old.unknownColor != unknownColor ||
      old.unknownBackground != unknownBackground;
}

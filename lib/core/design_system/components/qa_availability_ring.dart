import 'dart:async';

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_colors.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_motion.dart';

/// Cada tramo del anillo.
enum QaRingSegment { free, occupied, unknown }

/// Un tramo del anillo: [start] y [sweep] en fracción de vuelta (0 a 1),
/// empezando arriba y en sentido horario.
class QaRingArc {
  const QaRingArc(this.segment, this.start, this.sweep);

  final QaRingSegment segment;
  final double start;
  final double sweep;
}

/// Reparte el anillo entre libres, ocupados y sin datos, en proporción a su
/// cuenta (la capacidad es la suma). Con más de un tramo deja un pequeño
/// hueco entre ellos. Sin espacios no hay tramos.
List<QaRingArc> qaRingArcs({
  required int free,
  required int occupied,
  required int unknown,
  double gap = 0.012,
}) {
  final total = free + occupied + unknown;
  if (total <= 0) return const [];
  final parts = <(QaRingSegment, int)>[
    (QaRingSegment.free, free),
    (QaRingSegment.occupied, occupied),
    (QaRingSegment.unknown, unknown),
  ].where((part) => part.$2 > 0).toList();
  final gaps = parts.length > 1 ? gap * parts.length : 0.0;
  final room = 1 - gaps;
  final arcs = <QaRingArc>[];
  var start = gaps > 0 ? gap / 2 : 0.0;
  for (final (segment, count) in parts) {
    final sweep = room * count / total;
    arcs.add(QaRingArc(segment, start, sweep));
    start += sweep + (gaps > 0 ? gap : 0);
  }
  return arcs;
}

/// Dónde se dibuja el anillo: sobre una superficie normal o sobre una
/// superficie de marca (el héroe con degradado).
enum QaRingStyle { surface, onBrand }

/// Anillo de disponibilidad: libres (turquesa), ocupados (slate) y sin datos
/// (punteado, nunca un color plano), con [child] al centro (las libres). El
/// anillo **se dibuja una sola vez** al cargar (800 ms); con
/// `disableAnimations` aparece completo. Es un resumen visual: la misma
/// información va en texto (el centro y la leyenda), así que no expone
/// semántica propia.
class QaAvailabilityRing extends StatefulWidget {
  const QaAvailabilityRing({
    required this.free,
    required this.occupied,
    required this.unknown,
    this.size = 168,
    this.strokeWidth = 14,
    this.style = QaRingStyle.surface,
    this.child,
    super.key,
  });

  final int free;
  final int occupied;
  final int unknown;

  /// Diámetro exterior con el texto a 1×.
  final double size;
  final double strokeWidth;
  final QaRingStyle style;
  final Widget? child;

  @override
  State<QaAvailabilityRing> createState() => _QaAvailabilityRingState();
}

class _QaAvailabilityRingState extends State<QaAvailabilityRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (QaMotion.enabled(context)) {
      unawaited(_controller.forward());
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.qaColors;
    final onBrand = widget.style == QaRingStyle.onBrand;
    // El anillo crece con el texto (hasta 1,5×) para que las cifras del centro
    // quepan con el texto al 200 %.
    final grow = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.5);
    final size = widget.size * grow;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          ExcludeSemantics(
            child: RepaintBoundary(
              child: CustomPaint(
                size: Size.square(size),
                painter: _RingPainter(
                  progress: _controller,
                  arcs: qaRingArcs(
                    free: widget.free,
                    occupied: widget.occupied,
                    unknown: widget.unknown,
                  ),
                  strokeWidth: widget.strokeWidth,
                  free: onBrand ? QaColors.light.mint : colors.freeGraphic,
                  occupied: onBrand
                      ? colors.onBrand.withValues(alpha: 0.42)
                      : colors.occupied,
                  unknown: onBrand ? colors.onBrand : colors.unknown,
                  track: onBrand
                      ? colors.onBrand.withValues(alpha: 0.18)
                      : colors.paint,
                ),
              ),
            ),
          ),
          if (widget.child != null)
            Padding(
              padding: EdgeInsets.all(widget.strokeWidth + 8),
              child: Center(
                child: FittedBox(fit: BoxFit.scaleDown, child: widget.child),
              ),
            ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.arcs,
    required this.strokeWidth,
    required this.free,
    required this.occupied,
    required this.unknown,
    required this.track,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final List<QaRingArc> arcs;
  final double strokeWidth;
  final Color free;
  final Color occupied;
  final Color unknown;
  final Color track;

  static const double _turn = 2 * math.pi;
  static const double _top = -math.pi / 2;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(rect, 0, _turn, false, base..color = track);

    // El anillo se dibuja de principio a fin: cada tramo aparece cuando el
    // avance llega a él.
    final reach = Curves.easeOutCubic.transform(progress.value);
    for (final arc in arcs) {
      final drawn = ((reach - arc.start) / arc.sweep).clamp(0.0, 1.0);
      if (drawn <= 0) continue;
      final sweep = arc.sweep * drawn;
      switch (arc.segment) {
        case QaRingSegment.free:
          canvas.drawArc(
            rect,
            _top + arc.start * _turn,
            sweep * _turn,
            false,
            base
              ..color = free
              ..strokeCap = StrokeCap.round,
          );
        case QaRingSegment.occupied:
          canvas.drawArc(
            rect,
            _top + arc.start * _turn,
            sweep * _turn,
            false,
            base
              ..color = occupied
              ..strokeCap = StrokeCap.butt,
          );
        case QaRingSegment.unknown:
          _paintDashed(canvas, rect, arc.start, sweep, base..color = unknown);
      }
    }
  }

  /// Sin datos va punteado: rayitas separadas, nunca un trazo plano.
  void _paintDashed(
    Canvas canvas,
    Rect rect,
    double start,
    double sweep,
    Paint paint,
  ) {
    paint.strokeCap = StrokeCap.butt;
    const dash = 0.012;
    const period = 0.022;
    for (var t = 0.0; t < sweep; t += period) {
      final length = math.min(dash, sweep - t);
      canvas.drawArc(
        rect,
        _top + (start + t) * _turn,
        length * _turn,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.arcs.length != arcs.length ||
      !_sameArcs(old.arcs, arcs) ||
      old.strokeWidth != strokeWidth ||
      old.free != free ||
      old.occupied != occupied ||
      old.unknown != unknown ||
      old.track != track;

  static bool _sameArcs(List<QaRingArc> a, List<QaRingArc> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].segment != b[i].segment ||
          a[i].start != b[i].start ||
          a[i].sweep != b[i].sweep) {
        return false;
      }
    }
    return true;
  }
}

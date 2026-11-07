import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/core/design_system/painters/qa_hatch.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_colors.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_text_styles.dart';

/// Las ilustraciones propias de la app, dibujadas con `CustomPainter`.
enum QaIllustrationKind {
  /// Hilera de plazas de estacionamiento vistas desde arriba, con autos y una
  /// plaza libre resaltada.
  parking,

  /// Un auto visto desde arriba sobre su plaza.
  car,

  /// Un sensor sobre una plaza, emitiendo señal.
  sensor,

  /// Un sensor sin señal (para errores y dispositivos sin comunicación).
  signalLost,
}

/// Dibuja una [QaIllustrationKind] en un lienzo de proporción 8:5 (todo se
/// escala desde 240×150). Usa solo los tokens de color de la app, así sigue el
/// modo claro y oscuro. Es decorativa.
class QaIllustrationPainter extends CustomPainter {
  const QaIllustrationPainter({required this.kind, required this.colors});

  final QaIllustrationKind kind;
  final QaColors colors;

  /// Lienzo de diseño.
  static const double width = 240;
  static const double height = 150;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width / width, size.height / height);
    canvas
      ..save()
      ..translate(
        (size.width - width * scale) / 2,
        (size.height - height * scale) / 2,
      )
      ..scale(scale);
    _backdrop(canvas);
    switch (kind) {
      case QaIllustrationKind.parking:
        _parking(canvas);
      case QaIllustrationKind.car:
        _singleCar(canvas);
      case QaIllustrationKind.sensor:
        _sensor(canvas, lost: false);
      case QaIllustrationKind.signalLost:
        _sensor(canvas, lost: true);
    }
    canvas.restore();
  }

  /// Un fondo tonal suave (Mint) con dos destellos de marca.
  void _backdrop(Canvas canvas) {
    canvas
      ..drawCircle(
        const Offset(120, 78),
        68,
        Paint()..color = colors.mint.withValues(alpha: 0.9),
      )
      ..drawCircle(
        const Offset(36, 36),
        7,
        Paint()..color = colors.brandAccent.withValues(alpha: 0.9),
      )
      ..drawCircle(
        const Offset(208, 118),
        5,
        Paint()..color = colors.primary.withValues(alpha: 0.75),
      )
      ..drawCircle(
        const Offset(204, 30),
        3.5,
        Paint()..color = colors.freeGraphic.withValues(alpha: 0.8),
      );
  }

  Paint get _line => Paint()
    ..color = colors.onSurfaceMuted.withValues(alpha: 0.5)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;

  void _parking(Canvas canvas) {
    final panel = RRect.fromRectAndRadius(
      const Rect.fromLTWH(22, 24, 196, 104),
      const Radius.circular(18),
    );
    canvas
      ..drawRRect(
        panel.shift(const Offset(0, 4)),
        Paint()..color = colors.shadow.withValues(alpha: 0.10),
      )
      ..drawRRect(panel, Paint()..color = colors.surface)
      ..drawRRect(
        panel,
        Paint()
          ..color = colors.paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

    const left = 36.0;
    const bay = 42.0;
    // Líneas de las plazas: dos hileras con una calzada al centro.
    final line = _line;
    for (var i = 0; i <= 4; i++) {
      final x = left + i * bay;
      canvas
        ..drawLine(Offset(x, 34), Offset(x, 70), line)
        ..drawLine(Offset(x, 86), Offset(x, 120), line);
    }
    // Calzada discontinua.
    for (var x = 36.0; x < 204; x += 14) {
      canvas.drawLine(
        Offset(x, 78),
        Offset(x + 7, 78),
        line..color = colors.onSurfaceMuted.withValues(alpha: 0.3),
      );
    }

    void car(int column, {required bool top, required Color body}) {
      final rect = Rect.fromLTWH(
        left + column * bay + 7,
        top ? 38 : 90,
        bay - 14,
        top ? 28 : 26,
      );
      _car(canvas, rect, body, vertical: false);
    }

    car(0, top: true, body: colors.occupied);
    car(2, top: true, body: colors.primary);
    car(3, top: true, body: colors.occupied);
    car(1, top: false, body: colors.limited);
    car(2, top: false, body: colors.occupied);
    car(3, top: false, body: colors.primary);

    // La plaza libre resaltada, con su "P".
    final free = RRect.fromRectAndRadius(
      const Rect.fromLTWH(left + bay + 4, 37, bay - 8, 31),
      const Radius.circular(7),
    );
    canvas
      ..drawRRect(free, Paint()..color = colors.mint)
      ..drawRRect(
        free,
        Paint()
          ..color = colors.freeGraphic
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    final glyph = TextPainter(
      text: TextSpan(
        text: 'P',
        style: TextStyle(
          fontFamily: QaFonts.display,
          fontWeight: FontWeight.w700,
          fontSize: 22,
          color: colors.free,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    glyph.paint(
      canvas,
      Offset(
        free.center.dx - glyph.width / 2,
        free.center.dy - glyph.height / 2,
      ),
    );
  }

  void _singleCar(Canvas canvas) {
    // La plaza, con sus líneas.
    final bay = RRect.fromRectAndRadius(
      const Rect.fromLTWH(78, 16, 84, 122),
      const Radius.circular(14),
    );
    canvas
      ..drawRRect(bay, Paint()..color = colors.surface)
      ..drawRRect(
        bay,
        Paint()
          ..color = colors.onSurfaceMuted.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    _car(
      canvas,
      const Rect.fromLTWH(92, 28, 56, 98),
      colors.primary,
      vertical: true,
    );
    // Destellos.
    final spark = Paint()
      ..color = colors.brandAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawLine(const Offset(170, 44), const Offset(182, 44), spark)
      ..drawLine(const Offset(176, 38), const Offset(176, 50), spark)
      ..drawLine(const Offset(58, 104), const Offset(66, 104), spark)
      ..drawLine(const Offset(62, 100), const Offset(62, 108), spark);
  }

  void _sensor(Canvas canvas, {required bool lost}) {
    // La plaza.
    final bay = RRect.fromRectAndRadius(
      const Rect.fromLTWH(70, 78, 100, 56),
      const Radius.circular(12),
    );
    canvas
      ..drawRRect(bay, Paint()..color = colors.surface)
      ..drawRRect(
        bay,
        Paint()
          ..color = colors.onSurfaceMuted.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    _car(
      canvas,
      const Rect.fromLTWH(88, 90, 64, 32),
      lost ? colors.unknown : colors.occupied,
      vertical: false,
    );

    // El sensor y su señal.
    const center = Offset(120, 60);
    final tone = lost ? colors.unknown : colors.primary;
    for (var i = 1; i <= 3; i++) {
      final radius = 12.0 + i * 11;
      final rect = Rect.fromCircle(center: center, radius: radius);
      final paint = Paint()
        ..color = tone.withValues(alpha: lost ? 0.5 : 0.85 - i * 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      if (lost) {
        for (var a = -150.0; a < -30; a += 22) {
          canvas.drawArc(
            rect,
            a * math.pi / 180,
            9 * math.pi / 180,
            false,
            paint,
          );
        }
      } else {
        canvas.drawArc(
          rect,
          -150 * math.pi / 180,
          120 * math.pi / 180,
          false,
          paint,
        );
      }
    }
    canvas
      ..drawCircle(
        center,
        14,
        Paint()..color = lost ? colors.unknown : colors.primaryDark,
      )
      ..drawCircle(
        center,
        6,
        Paint()..color = lost ? colors.surface : colors.mint,
      );
    if (lost) {
      paintQaHatch(
        canvas,
        Rect.fromCircle(center: center, radius: 14).deflate(2),
        colors.surface,
        spacing: 4,
        strokeWidth: 1.2,
      );
      // Insignia de aviso.
      const badge = Offset(160, 40);
      canvas.drawCircle(badge, 12, Paint()..color = colors.alertFill);
      final cross = Paint()
        ..color = colors.ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas
        ..drawLine(
          badge + const Offset(-4.5, -4.5),
          badge + const Offset(4.5, 4.5),
          cross,
        )
        ..drawLine(
          badge + const Offset(4.5, -4.5),
          badge + const Offset(-4.5, 4.5),
          cross,
        );
    }
  }

  /// Un auto visto desde arriba. [vertical] lo orienta hacia arriba.
  void _car(Canvas canvas, Rect r, Color body, {required bool vertical}) {
    final shape = RRect.fromRectAndRadius(
      r,
      Radius.circular((vertical ? r.width : r.height) * 0.3),
    );
    canvas.drawRRect(shape, Paint()..color = body);
    final glass = Paint()..color = colors.surface.withValues(alpha: 0.85);
    if (vertical) {
      final w = r.width * 0.7;
      final x = r.left + (r.width - w) / 2;
      canvas
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, r.top + r.height * 0.16, w, r.height * 0.2),
            const Radius.circular(5),
          ),
          glass,
        )
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, r.top + r.height * 0.66, w, r.height * 0.14),
            const Radius.circular(4),
          ),
          glass,
        );
    } else {
      final h = r.height * 0.7;
      final y = r.top + (r.height - h) / 2;
      canvas
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(r.left + r.width * 0.2, y, r.width * 0.2, h),
            const Radius.circular(5),
          ),
          glass,
        )
        ..drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(r.left + r.width * 0.68, y, r.width * 0.14, h),
            const Radius.circular(4),
          ),
          glass,
        );
    }
  }

  @override
  bool shouldRepaint(QaIllustrationPainter old) =>
      old.kind != kind || old.colors != colors;
}

import 'dart:async';

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/core/design_system/components/qa_skeleton.dart';
import 'package:quadrapp_mobile/core/design_system/components/qa_status_chip.dart';
import 'package:quadrapp_mobile/core/design_system/painters/qa_hatch.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_colors.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_motion.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_radii.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_spacing.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_tone.dart';

/// Estado visual de un espacio del mapa.
enum QaSpaceState { free, occupied, unknown }

/// Un espacio en el mapa. [x] e [y] son posiciones en unidades de espacio
/// (columna y fila); cada espacio ocupa 1 × 1 unidades.
@immutable
class QaSpaceCell {
  const QaSpaceCell({
    required this.id,
    required this.x,
    required this.y,
    required this.state,
  });

  final int id;
  final double x;
  final double y;
  final QaSpaceState state;

  @override
  bool operator ==(Object other) =>
      other is QaSpaceCell &&
      other.id == id &&
      other.x == x &&
      other.y == y &&
      other.state == state;

  @override
  int get hashCode => Object.hash(id, x, y, state);
}

/// Resumen de una zona para la lista alternativa accesible.
@immutable
class QaZoneSummary {
  const QaZoneSummary({
    required this.name,
    required this.freeText,
    required this.occupiedText,
    required this.unknownText,
    required this.semanticLabel,
  });

  final String name;

  /// Por ejemplo "12 libres".
  final String freeText;
  final String occupiedText;
  final String unknownText;

  /// Por ejemplo "Zona A: 12 libres, 20 ocupados, 1 sin datos".
  final String semanticLabel;
}

/// Textos de la leyenda del mapa.
@immutable
class QaSpaceLegend {
  const QaSpaceLegend({
    required this.free,
    required this.occupied,
    required this.unknown,
  });

  final String free;
  final String occupied;
  final String unknown;
}

/// Mapa de espacios en tiempo real, dibujado con `CustomPainter`:
/// libre = espacio vacío con borde verde, ocupado = silueta de auto rellena en
/// rojo, sin datos = rayado diagonal gris. Incluye leyenda y una lista de
/// zonas con sus conteos como alternativa accesible; el lienzo se expone a
/// TalkBack como un solo resumen ([summaryLabel]) anunciado como región viva.
///
/// Un espacio que cambia de estado hace un pulso de 400 ms (se omite si el
/// usuario desactivó las animaciones). Vacío y error se resuelven con
/// `QaEmptyState` y `QaErrorState` en su lugar.
class QaSpaceMap extends StatefulWidget {
  const QaSpaceMap({
    required this.cells,
    required this.zones,
    required this.summaryLabel,
    required this.legend,
    this.isStale = false,
    super.key,
  }) : _loadingLabel = null;

  const QaSpaceMap.loading({required String semanticLabel, super.key})
    : cells = const [],
      zones = const [],
      summaryLabel = '',
      legend = null,
      isStale = false,
      _loadingLabel = semanticLabel;

  final List<QaSpaceCell> cells;
  final List<QaZoneSummary> zones;

  /// Por ejemplo "Mapa: 34 libres, 83 ocupados, 3 sin datos".
  final String summaryLabel;
  final QaSpaceLegend? legend;

  /// Datos desactualizados: el marco pasa a un contorno "limitada".
  final bool isStale;
  final String? _loadingLabel;

  @override
  State<QaSpaceMap> createState() => _QaSpaceMapState();
}

class _QaSpaceMapState extends State<QaSpaceMap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  Set<int> _changed = const {};

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: QaMotion.pulse,
      value: 1,
    );
  }

  @override
  void didUpdateWidget(QaSpaceMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (listEquals(oldWidget.cells, widget.cells)) return;
    final before = {for (final c in oldWidget.cells) c.id: c.state};
    final changed = {
      for (final c in widget.cells)
        if (before[c.id] != null && before[c.id] != c.state) c.id,
    };
    if (changed.isNotEmpty && QaMotion.enabled(context)) {
      _changed = changed;
      unawaited(_pulse.forward(from: 0));
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loadingLabel = widget._loadingLabel;
    if (loadingLabel != null) {
      return QaLoadingRegion(
        semanticLabel: loadingLabel,
        child: const QaSkeleton(
          height: 220,
          borderRadius: QaRadii.cardRadius,
        ),
      );
    }

    final colors = context.qaColors;
    final theme = Theme.of(context);
    final legend = widget.legend;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: QaRadii.cardRadius,
            border: Border.all(
              color: widget.isStale ? colors.limitedText : colors.paint,
              width: widget.isStale ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(QaSpacing.md),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final layout = _MapLayout.fit(
                  widget.cells,
                  constraints.maxWidth,
                );
                return Semantics(
                  liveRegion: true,
                  label: widget.summaryLabel,
                  child: ExcludeSemantics(
                    child: RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: _pulse,
                        builder: (context, _) => CustomPaint(
                          size: Size(constraints.maxWidth, layout.height),
                          painter: _SpaceMapPainter(
                            cells: widget.cells,
                            layout: layout,
                            colors: colors,
                            changed: _changed,
                            pulse: _pulse.value,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        if (legend != null) ...[
          const SizedBox(height: QaSpacing.md),
          Wrap(
            spacing: QaSpacing.sm,
            runSpacing: QaSpacing.sm,
            children: [
              QaStatusChip(tone: QaTone.free, label: legend.free),
              QaStatusChip(tone: QaTone.occupied, label: legend.occupied),
              QaStatusChip(tone: QaTone.unknown, label: legend.unknown),
            ],
          ),
        ],
        if (widget.zones.isNotEmpty) ...[
          const SizedBox(height: QaSpacing.lg),
          for (final zone in widget.zones)
            Padding(
              padding: const EdgeInsets.only(bottom: QaSpacing.md),
              child: Semantics(
                container: true,
                label: zone.semanticLabel,
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(zone.name, style: theme.textTheme.titleSmall),
                      const SizedBox(height: QaSpacing.xs),
                      Wrap(
                        spacing: QaSpacing.sm,
                        runSpacing: QaSpacing.sm,
                        children: [
                          QaStatusChip(tone: QaTone.free, label: zone.freeText),
                          QaStatusChip(
                            tone: QaTone.occupied,
                            label: zone.occupiedText,
                          ),
                          QaStatusChip(
                            tone: QaTone.unknown,
                            label: zone.unknownText,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

/// Geometría del mapa: cuántas columnas y filas hay y qué tamaño tiene cada
/// espacio para caber en el ancho disponible.
@immutable
class _MapLayout {
  const _MapLayout({
    required this.columns,
    required this.rows,
    required this.unitWidth,
    required this.unitHeight,
    required this.offsetX,
  });

  factory _MapLayout.fit(List<QaSpaceCell> cells, double width) {
    final maxX = cells.fold<double>(0, (m, c) => math.max(m, c.x));
    final maxY = cells.fold<double>(0, (m, c) => math.max(m, c.y));
    final columns = maxX.floor() + 1;
    final rows = maxY.floor() + 1;
    final unitWidth = math.min(width / columns, 56).toDouble();
    return _MapLayout(
      columns: columns,
      rows: rows,
      unitWidth: unitWidth,
      unitHeight: unitWidth * 1.6,
      offsetX: (width - unitWidth * columns) / 2,
    );
  }

  final int columns;
  final int rows;
  final double unitWidth;
  final double unitHeight;
  final double offsetX;

  double get height => unitHeight * rows;

  @override
  bool operator ==(Object other) =>
      other is _MapLayout &&
      other.columns == columns &&
      other.rows == rows &&
      other.unitWidth == unitWidth &&
      other.offsetX == offsetX;

  @override
  int get hashCode => Object.hash(columns, rows, unitWidth, offsetX);

  Rect slot(QaSpaceCell cell) => Rect.fromLTWH(
    offsetX + cell.x * unitWidth,
    cell.y * unitHeight,
    unitWidth,
    unitHeight,
  );
}

class _SpaceMapPainter extends CustomPainter {
  const _SpaceMapPainter({
    required this.cells,
    required this.layout,
    required this.colors,
    required this.changed,
    required this.pulse,
  });

  final List<QaSpaceCell> cells;
  final _MapLayout layout;
  final QaColors colors;
  final Set<int> changed;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final lines = Paint()
      ..color = colors.paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (final cell in cells) {
      final slot = layout.slot(cell).deflate(2);
      final rrect = RRect.fromRectAndRadius(slot, const Radius.circular(6));
      canvas.drawRRect(rrect, lines);
      switch (cell.state) {
        case QaSpaceState.free:
          canvas.drawRRect(
            rrect.deflate(1),
            Paint()
              ..color = colors.freeGraphic
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
        case QaSpaceState.occupied:
          _paintCar(canvas, slot.deflate(4));
        case QaSpaceState.unknown:
          canvas
            ..save()
            ..clipRRect(rrect);
          paintQaHatch(canvas, slot, colors.unknown, spacing: 7);
          canvas
            ..restore()
            ..drawRRect(
              rrect,
              Paint()
                ..color = colors.unknown
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1.5,
            );
      }
      if (changed.contains(cell.id) && pulse < 1) {
        final tone = switch (cell.state) {
          QaSpaceState.free => QaTone.free,
          QaSpaceState.occupied => QaTone.occupied,
          QaSpaceState.unknown => QaTone.unknown,
        };
        canvas.drawRRect(
          rrect.inflate(6 * pulse),
          Paint()
            ..color = colors.accent(tone).withValues(alpha: 1 - pulse)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      }
    }
  }

  /// Silueta de auto vista desde arriba, rellena en slate (ocupado no va en
  /// rojo).
  void _paintCar(Canvas canvas, Rect r) {
    final body = RRect.fromRectAndRadius(r, Radius.circular(r.width * 0.28));
    canvas.drawRRect(body, Paint()..color = colors.occupied);
    final glass = Paint()..color = colors.surface.withValues(alpha: 0.85);
    final glassWidth = r.width * 0.68;
    final left = r.left + (r.width - glassWidth) / 2;
    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            left,
            r.top + r.height * 0.2,
            glassWidth,
            r.height * 0.16,
          ),
          const Radius.circular(3),
        ),
        glass,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            left,
            r.top + r.height * 0.66,
            glassWidth,
            r.height * 0.12,
          ),
          const Radius.circular(3),
        ),
        glass,
      );
  }

  @override
  bool shouldRepaint(_SpaceMapPainter oldDelegate) =>
      !listEquals(oldDelegate.cells, cells) ||
      oldDelegate.layout != layout ||
      oldDelegate.colors != colors ||
      !setEquals(oldDelegate.changed, changed) ||
      oldDelegate.pulse != pulse;
}

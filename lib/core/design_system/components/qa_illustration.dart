import 'package:flutter/widgets.dart';
import 'package:quadrapp_mobile/core/design_system/painters/qa_illustrations.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_colors.dart';

export 'package:quadrapp_mobile/core/design_system/painters/qa_illustrations.dart'
    show QaIllustrationKind;

/// Una ilustración vectorial propia (plazas, auto visto desde arriba, sensor),
/// para encabezados, estados vacíos y errores. Decorativa: no expone
/// semántica (el título y el texto de al lado dicen lo mismo).
class QaIllustration extends StatelessWidget {
  const QaIllustration({required this.kind, this.height = 120, super.key});

  final QaIllustrationKind kind;

  /// Alto; el ancho sale de la proporción 8:5.
  final double height;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          size: Size(
            height * QaIllustrationPainter.width / QaIllustrationPainter.height,
            height,
          ),
          painter: QaIllustrationPainter(kind: kind, colors: context.qaColors),
        ),
      ),
    );
  }
}

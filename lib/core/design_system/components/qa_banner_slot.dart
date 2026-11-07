import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/core/design_system/components/qa_animated_size.dart';
import 'package:quadrapp_mobile/core/design_system/components/qa_banner.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_spacing.dart';

/// Hueco para un [QaBanner] dentro de un formulario: el aviso aparece y
/// desaparece animando la altura (200 ms), así lo que está debajo no salta.
/// Sin aviso ocupa 0 dp; con aviso, el aviso más 16 dp de separación arriba.
class QaBannerSlot extends StatelessWidget {
  const QaBannerSlot({this.banner, super.key});

  /// El aviso a mostrar, o `null` si no hay ninguno.
  final QaBanner? banner;

  @override
  Widget build(BuildContext context) {
    return QaAnimatedSize(
      child: SizedBox(
        width: double.infinity,
        child: banner == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(top: QaSpacing.lg),
                child: banner,
              ),
      ),
    );
  }
}

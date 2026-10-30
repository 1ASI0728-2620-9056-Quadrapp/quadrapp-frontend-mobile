import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_motion.dart';

/// `AnimatedSize` que respeta `MediaQuery.disableAnimations`: sin animaciones
/// el cambio de tamaño es inmediato (y no se usa `AnimatedSize` con duración
/// cero, que no está permitido durante el layout).
class QaAnimatedSize extends StatelessWidget {
  const QaAnimatedSize({
    required this.child,
    this.alignment = Alignment.topCenter,
    super.key,
  });

  final Widget child;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    if (!QaMotion.enabled(context)) return child;
    return AnimatedSize(
      duration: QaMotion.resize,
      alignment: alignment,
      child: child,
    );
  }
}

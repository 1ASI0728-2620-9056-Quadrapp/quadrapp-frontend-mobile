import 'package:flutter/widgets.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_motion.dart';

/// Retroalimentación al tocar: el contenido se encoge a 0,98 mientras hay un
/// dedo encima. Escucha los punteros sin competir por el gesto (el botón o la
/// tarjeta de dentro sigue recibiendo el toque). Sin animaciones (ajuste del
/// sistema) no hace nada.
class QaPressScale extends StatefulWidget {
  const QaPressScale({required this.child, this.enabled = true, super.key});

  final Widget child;

  /// Con `false` (un botón deshabilitado) no reacciona.
  final bool enabled;

  /// Escala mientras se presiona.
  static const double pressedScale = 0.98;

  @override
  State<QaPressScale> createState() => _QaPressScaleState();
}

class _QaPressScaleState extends State<QaPressScale> {
  bool _pressed = false;

  void _set({required bool pressed}) {
    if (_pressed == pressed || !mounted) return;
    setState(() => _pressed = pressed);
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.enabled && QaMotion.enabled(context);
    return Listener(
      onPointerDown: active ? (_) => _set(pressed: true) : null,
      onPointerUp: (_) => _set(pressed: false),
      onPointerCancel: (_) => _set(pressed: false),
      child: AnimatedScale(
        scale: active && _pressed ? QaPressScale.pressedScale : 1,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_motion.dart';

/// Entrada escalonada: el elemento aparece con un fade y un pequeño
/// desplazamiento hacia arriba, con un retraso proporcional a su [index].
/// Ocurre **una sola vez**, al montarse; reconstruir el widget no la repite.
/// Con `disableAnimations` aparece de inmediato. El retraso va dentro de una
/// sola animación (sin temporizadores), así que no deja nada pendiente.
class QaStagger extends StatefulWidget {
  const QaStagger({
    required this.index,
    required this.child,
    this.step = const Duration(milliseconds: 70),
    this.maxSteps = 6,
    super.key,
  });

  final int index;
  final Widget child;

  /// Retraso entre un elemento y el siguiente.
  final Duration step;

  /// Tope del retraso (la lista larga no tarda en aparecer).
  final int maxSteps;

  static const Duration _entrance = Duration(milliseconds: 420);

  @override
  State<QaStagger> createState() => _QaStaggerState();
}

class _QaStaggerState extends State<QaStagger>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    final delay = widget.step * math.min(widget.index, widget.maxSteps);
    final total = QaStagger._entrance + delay;
    _controller = AnimationController(vsync: this, duration: total);
    _fade = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        delay.inMilliseconds / total.inMilliseconds,
        1,
        curve: Curves.easeOutCubic,
      ),
    );
  }

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
    return AnimatedBuilder(
      animation: _fade,
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: _fade.value,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - _fade.value)),
          child: child,
        ),
      ),
    );
  }
}

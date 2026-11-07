import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_motion.dart';

/// Una cifra que cuenta desde 0 hasta su valor **una sola vez**, al cargar.
/// Los cambios de valor posteriores (un espacio que se libera en tiempo real)
/// se muestran de inmediato, sin volver a contar. Con `disableAnimations` la
/// cifra aparece ya en su valor.
///
/// Se anuncia siempre con su valor final ([semanticLabel] o el número): un
/// lector de pantalla nunca lee los números intermedios.
class QaCountUp extends StatefulWidget {
  const QaCountUp({
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 800),
    this.semanticLabel,
    this.textAlign,
    super.key,
  });

  final int value;
  final TextStyle? style;
  final Duration duration;
  final String? semanticLabel;
  final TextAlign? textAlign;

  @override
  State<QaCountUp> createState() => _QaCountUpState();
}

class _QaCountUpState extends State<QaCountUp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (QaMotion.enabled(context) && widget.value > 0) {
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
    return Semantics(
      label: widget.semanticLabel ?? '${widget.value}',
      excludeSemantics: true,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final shown = _controller.isCompleted
              ? widget.value
              : (widget.value *
                        Curves.easeOutCubic.transform(_controller.value))
                    .round();
          return Text(
            '$shown',
            style: widget.style,
            textAlign: widget.textAlign,
          );
        },
      ),
    );
  }
}

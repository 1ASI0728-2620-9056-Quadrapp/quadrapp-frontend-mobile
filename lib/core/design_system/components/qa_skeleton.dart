import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_colors.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_motion.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_radii.dart';

/// El brillo suave que recorre los bloques de carga de un [QaLoadingRegion].
class _ShimmerScope extends InheritedWidget {
  const _ShimmerScope({required this.animation, required super.child});

  final Animation<double> animation;

  static Animation<double>? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ShimmerScope>()?.animation;

  @override
  bool updateShouldNotify(_ShimmerScope oldWidget) =>
      oldWidget.animation != animation;
}

/// Bloque de carga. Los skeletons reemplazan a los spinners de pantalla
/// completa. Dentro de un [QaLoadingRegion] llevan un brillo suave que los
/// recorre (sin animaciones, o fuera de una región, son estáticos).
class QaSkeleton extends StatelessWidget {
  const QaSkeleton({
    this.width,
    this.height = 16,
    this.borderRadius = QaRadii.controlRadius,
    super.key,
  });

  /// Una línea de texto.
  const QaSkeleton.line({this.width, super.key})
    : height = 14,
      borderRadius = QaRadii.controlRadius;

  final double? width;
  final double height;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = context.qaColors;
    final shimmer = _ShimmerScope.maybeOf(context);
    final base = colors.surfaceMuted;
    // Un tono apenas más claro (o más oscuro en modo oscuro) que el bloque.
    final glint = Color.lerp(base, colors.paint, 0.55)!;

    Widget block(double t) => DecoratedBox(
      decoration: BoxDecoration(
        color: shimmer == null ? base : null,
        gradient: shimmer == null
            ? null
            : LinearGradient(
                begin: Alignment(-2.4 + 4.8 * t, 0),
                end: Alignment(-0.6 + 4.8 * t, 0),
                colors: [base, glint, base],
              ),
        borderRadius: borderRadius,
      ),
      child: SizedBox(width: width, height: height),
    );

    if (shimmer == null) return block(0);
    return AnimatedBuilder(
      animation: shimmer,
      builder: (context, _) => block(shimmer.value),
    );
  }
}

/// Envuelve un conjunto de [QaSkeleton] con una única etiqueta accesible
/// ("Cargando…"), oculta los bloques a TalkBack y les da un brillo suave. El
/// brillo se repite unos segundos (un skeleton que tarda más es un problema
/// de carga, no algo que merezca una animación eterna) y respeta
/// `disableAnimations`.
class QaLoadingRegion extends StatefulWidget {
  const QaLoadingRegion({
    required this.semanticLabel,
    required this.child,
    super.key,
  });

  final String semanticLabel;
  final Widget child;

  @override
  State<QaLoadingRegion> createState() => _QaLoadingRegionState();
}

class _QaLoadingRegionState extends State<QaLoadingRegion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started || !QaMotion.enabled(context)) return;
    _started = true;
    unawaited(_controller.repeat(count: 5));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animated = QaMotion.enabled(context);
    final child = ExcludeSemantics(child: widget.child);
    return Semantics(
      container: true,
      label: widget.semanticLabel,
      child: animated
          ? _ShimmerScope(animation: _controller, child: child)
          : child,
    );
  }
}

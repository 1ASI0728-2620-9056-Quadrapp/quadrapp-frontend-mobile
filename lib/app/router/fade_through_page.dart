import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';

/// Página con transición fade-through de 250 ms (las pantallas de acceso):
/// la que sale se desvanece en el primer 30 % y la que entra aparece después,
/// con un leve escalado de 0,92 a 1. Con `disableAnimations` no hay
/// transición.
CustomTransitionPage<void> fadeThroughPage({
  required LocalKey key,
  required Widget child,
}) => CustomTransitionPage<void>(
  key: key,
  child: child,
  transitionDuration: QaMotion.fadeThrough,
  reverseTransitionDuration: QaMotion.fadeThrough,
  transitionsBuilder: (context, animation, secondaryAnimation, child) {
    if (!QaMotion.enabled(context)) return child;
    final fadeIn = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.3, 1, curve: Curves.easeOut),
    );
    final fadeOut = ReverseAnimation(
      CurvedAnimation(
        parent: secondaryAnimation,
        curve: const Interval(0, 0.3, curve: Curves.easeIn),
      ),
    );
    return FadeTransition(
      opacity: fadeOut,
      child: FadeTransition(
        opacity: fadeIn,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.92, end: 1).animate(fadeIn),
          child: child,
        ),
      ),
    );
  },
);

import 'dart:async';

import 'package:flutter/widgets.dart';

/// Avisa que se tocó otra vez la pestaña activa de la barra inferior.
///
/// Lo emite el shell de la app (`app/shell`) y lo escuchan las pantallas raíz
/// de cada pestaña con [QaScrollToTopOnReselect], que suben al inicio. Vive en
/// el sistema de diseño para que las pantallas de `composition` y de los
/// contextos lo usen sin conocer el shell ni el router.
class QaTabReselectSignal extends ChangeNotifier {
  int? _tab;

  /// La pestaña tocada por última vez estando ya activa.
  int? get tab => _tab;

  /// Se tocó la pestaña [tab] estando ya activa.
  void reselected(int tab) {
    _tab = tab;
    notifyListeners();
  }
}

/// Entrega un [QaTabReselectSignal] a las pantallas de la subred.
class QaTabReselectScope extends InheritedNotifier<QaTabReselectSignal> {
  const QaTabReselectScope({
    required QaTabReselectSignal signal,
    required super.child,
    super.key,
  }) : super(notifier: signal);

  /// La señal más cercana, o `null` fuera del shell (por ejemplo, en pruebas).
  static QaTabReselectSignal? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<QaTabReselectScope>()?.notifier;
}

/// Sube [controller] al inicio (animando, salvo con `disableAnimations`)
/// cuando se vuelve a tocar la pestaña [tabIndex]. Envuelve el contenido de
/// una pantalla raíz de pestaña; sin shell no hace nada.
class QaScrollToTopOnReselect extends StatefulWidget {
  const QaScrollToTopOnReselect({
    required this.tabIndex,
    required this.controller,
    required this.child,
    super.key,
  });

  final int tabIndex;
  final ScrollController controller;
  final Widget child;

  @override
  State<QaScrollToTopOnReselect> createState() =>
      _QaScrollToTopOnReselectState();
}

class _QaScrollToTopOnReselectState extends State<QaScrollToTopOnReselect> {
  QaTabReselectSignal? _signal;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final signal = QaTabReselectScope.maybeOf(context);
    if (signal == _signal) return;
    _signal?.removeListener(_onReselected);
    _signal = signal?..addListener(_onReselected);
  }

  void _onReselected() {
    if (_signal?.tab != widget.tabIndex || !widget.controller.hasClients) {
      return;
    }
    final animate = !MediaQuery.disableAnimationsOf(context);
    if (animate) {
      unawaited(
        widget.controller.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        ),
      );
    } else {
      widget.controller.jumpTo(0);
    }
  }

  @override
  void dispose() {
    _signal?.removeListener(_onReselected);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

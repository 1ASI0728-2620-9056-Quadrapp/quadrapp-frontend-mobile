// docs/02: navegación principal de cada experiencia (Conductor y Operación)
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:quadrapp_mobile/app/shell/shell_tabs.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';

/// Estructura de las pestañas de una experiencia ([AppTab.driver] para el
/// Conductor, [OpsTab.operations] para Operación): el contenido de la rama
/// activa y, debajo, la barra de navegación inferior.
///
/// - Cada pestaña conserva su estado (las ramas siguen montadas, ocultas).
/// - Tocar la pestaña activa vuelve a su raíz y sube al inicio
///   ([QaTabReselectSignal]).
/// - Atrás en la raíz de otra pestaña lleva a la primera, no cierra la app.
/// - La barra solo existe aquí: `/login`, `/login/verify`, `/gallery` y
///   `/debug/*` están fuera del shell.
class AppShell extends StatefulWidget {
  const AppShell({
    required this.navigationShell,
    required this.tabs,
    required this.children,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  /// Los destinos de la barra, en el orden de las ramas.
  final List<ShellTab> tabs;

  /// El navegador de cada rama, en el mismo orden que [tabs].
  final List<Widget> children;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final QaTabReselectSignal _reselect = QaTabReselectSignal();

  @override
  void dispose() {
    _reselect.dispose();
    super.dispose();
  }

  void _select(int index) {
    final current = widget.navigationShell.currentIndex;
    widget.navigationShell.goBranch(index, initialLocation: index == current);
    if (index == current) _reselect.reselected(index);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.qaColors;
    final current = widget.navigationShell.currentIndex;

    return PopScope(
      // En la raíz de otra pestaña, "atrás" va a la primera.
      canPop: current == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) widget.navigationShell.goBranch(0);
      },
      child: QaTabReselectScope(
        signal: _reselect,
        child: Scaffold(
          body: _FadeBranches(current: current, children: widget.children),
          bottomNavigationBar: DecoratedBox(
            // Se separa del contenido con un borde de 1 dp, sin sombra.
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.paint)),
            ),
            child: NavigationBar(
              selectedIndex: current,
              onDestinationSelected: _select,
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              destinations: [
                for (final item in widget.tabs)
                  NavigationDestination(
                    icon: Icon(item.icon),
                    selectedIcon: Icon(item.selectedIcon),
                    label: item.label(l10n),
                    // Sin tooltip: la etiqueta ya está siempre visible.
                    tooltip: '',
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Las ramas apiladas: todas siguen montadas (conservan su estado) pero solo
/// se ve la activa, que aparece con un fade de 200 ms (sin animaciones, de
/// golpe). La anterior se oculta al instante: el fade es solo de entrada, así
/// no hay un momento con dos pantallas mezcladas.
class _FadeBranches extends StatelessWidget {
  const _FadeBranches({required this.current, required this.children});

  final int current;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        for (var i = 0; i < children.length; i++)
          _FadeBranch(active: i == current, child: children[i]),
      ],
    );
  }
}

class _FadeBranch extends StatefulWidget {
  const _FadeBranch({required this.active, required this.child});

  final bool active;
  final Widget child;

  @override
  State<_FadeBranch> createState() => _FadeBranchState();
}

class _FadeBranchState extends State<_FadeBranch>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: QaMotion.tab,
    value: widget.active ? 1 : 0,
  );

  @override
  void didUpdateWidget(_FadeBranch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active == oldWidget.active) return;
    if (!widget.active) {
      _controller.value = 0;
    } else if (QaMotion.enabled(context)) {
      unawaited(_controller.forward(from: 0));
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
    // La estructura no cambia nunca: así el estado de la rama se conserva.
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) => Offstage(
        offstage: _controller.isDismissed,
        child: FadeTransition(
          opacity: _controller,
          child: IgnorePointer(
            ignoring: !widget.active,
            child: ExcludeSemantics(
              excluding: !widget.active,
              child: TickerMode(enabled: widget.active, child: child!),
            ),
          ),
        ),
      ),
    );
  }
}

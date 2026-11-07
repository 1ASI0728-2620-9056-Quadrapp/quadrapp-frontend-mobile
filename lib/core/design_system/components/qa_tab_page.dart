import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/core/design_system/components/qa_tab_reselect.dart';
import 'package:quadrapp_mobile/core/design_system/components/qa_top_bar.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_colors.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_spacing.dart';

/// Encabezado de una pantalla raíz de pestaña: el título (encabezado
/// semántico) y, debajo, una línea de contexto (por ejemplo, la institución).
class QaTabHeader extends StatelessWidget {
  const QaTabHeader({required this.title, this.subtitle, super.key});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = this.subtitle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: theme.textTheme.headlineLarge),
        ),
        if (subtitle != null && subtitle.isNotEmpty) ...[
          const SizedBox(height: QaSpacing.xs),
          Text(
            subtitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: context.qaColors.onSurfaceMuted,
            ),
          ),
        ],
      ],
    );
  }
}

/// Una pantalla raíz de pestaña: la barra superior del diseño (`QaTopBar`) y,
/// debajo, una sola columna de hasta 480 dp, centrada, con 16 dp a los lados;
/// se desplaza (el texto al 200 % no se corta) y sube al inicio al volver a
/// tocar su pestaña.
///
/// Con `onBack` la pantalla no es una pestaña sino una a la que se llega desde
/// otra (por ejemplo, la cuenta): la barra lleva la flecha de volver y no hay
/// pestaña que re-tocar.
///
/// La barra inferior la pone el shell de la app; esta pantalla solo ocupa el
/// espacio que queda sobre ella.
class QaTabPage extends StatefulWidget {
  const QaTabPage({
    required this.title,
    required this.children,
    this.tabIndex,
    this.action,
    this.onBack,
    this.backLabel,
    this.footer,
    this.onRefresh,
    super.key,
  });

  /// Posición de la pestaña en la barra inferior; `null` si no es una pestaña.
  final int? tabIndex;
  final String title;
  final QaTopBarAction? action;
  final VoidCallback? onBack;
  final String? backLabel;
  final List<Widget> children;

  /// Pie anclado al borde inferior (por ejemplo, la acción principal al
  /// alcance del pulgar). Si el contenido es más alto que la pantalla, va tras
  /// él.
  final Widget? footer;

  /// Deslizar hacia abajo recarga la pantalla; sin él no hay recarga.
  final Future<void> Function()? onRefresh;

  @override
  State<QaTabPage> createState() => _QaTabPageState();
}

class _QaTabPageState extends State<QaTabPage> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTab = widget.tabIndex != null;
    final body = LayoutBuilder(
      builder: (context, constraints) {
        final side = math.max(
          QaSpacing.screen,
          (constraints.maxWidth - 480) / 2,
        );
        // El contenido mide al menos la pantalla: así el pie llega al borde
        // inferior sin depender de intrínsecos.
        final scrollView = SingleChildScrollView(
          controller: _scroll,
          physics: widget.onRefresh == null
              ? null
              : const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            side,
            QaSpacing.lg,
            side,
            QaSpacing.xl,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(
                0,
                constraints.maxHeight - QaSpacing.lg - QaSpacing.xl,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: widget.children,
                ),
                if (widget.footer != null) ...[
                  const SizedBox(height: QaSpacing.xl),
                  widget.footer!,
                ],
              ],
            ),
          ),
        );
        final onRefresh = widget.onRefresh;
        return onRefresh == null
            ? scrollView
            : RefreshIndicator(onRefresh: onRefresh, child: scrollView);
      },
    );

    return Scaffold(
      body: Column(
        children: [
          QaTopBar(
            title: widget.title,
            action: widget.action,
            onBack: widget.onBack,
            backLabel: widget.backLabel,
          ),
          Expanded(
            child: isTab
                ? QaScrollToTopOnReselect(
                    tabIndex: widget.tabIndex!,
                    controller: _scroll,
                    child: body,
                  )
                // Sin barra inferior, el contenido respeta el borde de abajo.
                : SafeArea(top: false, child: body),
          ),
        ],
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/core/design_system/components/qa_top_bar.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_colors.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_radii.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_spacing.dart';

/// Estructura de las pantallas de acceso del diseño: una hoja blanca con
/// mucho aire, sin zona de marca.
///
/// - Sin [onBack] (el correo): arriba, el logo y «Quadrapp»; debajo, el
///   titular ([heading]).
/// - Con [onBack] (el código): la barra superior con la flecha de volver y
///   [topBarTitle]; debajo, el [icon] en un recuadro menta y el titular.
///
/// El contenido ([children]) se desplaza (el texto al 200 % y el teclado no
/// lo cortan) y el [footer] queda anclado abajo: es el texto legal o las
/// acciones secundarias. Una sola columna de hasta 480 dp, centrada.
class QaAuthScaffold extends StatelessWidget {
  const QaAuthScaffold({
    required this.heading,
    required this.children,
    this.topBarTitle,
    this.onBack,
    this.backLabel,
    this.icon,
    this.footer,
    super.key,
  }) : assert(
         onBack == null || topBarTitle != null,
         'Con onBack la barra superior necesita su título.',
       );

  /// Aire sobre el contenido (el diseño deja ~40 dp bajo la barra de estado).
  static const double _topPadding = 40;

  /// El titular de la pantalla (encabezado semántico).
  final String heading;
  final List<Widget> children;

  /// Título de la barra superior (solo con [onBack]).
  final String? topBarTitle;
  final VoidCallback? onBack;
  final String? backLabel;

  /// Ícono del recuadro menta sobre el titular (solo con [onBack]).
  final IconData? icon;

  /// Pie anclado abajo.
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.qaColors;
    final hasBack = onBack != null;
    final largeText = MediaQuery.textScalerOf(context).scale(16) >= 22;

    final headingText = Semantics(
      header: true,
      child: Text(
        heading,
        style: hasBack
            ? theme.textTheme.headlineMedium
            : theme.textTheme.headlineLarge,
      ),
    );

    // Arriba: el logo y el nombre (correo) o el recuadro menta (código).
    final Widget? leading = hasBack
        ? (icon == null
              ? null
              : Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: _IconTile(icon: icon!),
                ))
        : Row(
            children: [
              const QaBrandMark(size: 40),
              // Con el texto muy grande el nombre se oculta y queda el logo
              // (como en la barra superior).
              if (!largeText) ...const [
                SizedBox(width: QaSpacing.md),
                _Wordmark(),
              ],
            ],
          );

    return Scaffold(
      backgroundColor: colors.surface,
      body: Column(
        children: [
          if (hasBack)
            QaTopBar(
              title: topBarTitle!,
              onBack: onBack,
              backLabel: backLabel,
            ),
          Expanded(
            child: SafeArea(
              top: !hasBack,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final side = math.max(
                    QaSpacing.xl,
                    (constraints.maxWidth - 480) / 2,
                  );
                  return SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(
                      side,
                      _topPadding,
                      side,
                      QaSpacing.xl,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: math.max(
                          0,
                          constraints.maxHeight - _topPadding - QaSpacing.xl,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (leading != null) ...[
                                leading,
                                SizedBox(
                                  height: hasBack
                                      ? QaSpacing.xl
                                      : QaSpacing.xxl,
                                ),
                              ],
                              headingText,
                              const SizedBox(height: QaSpacing.md),
                              ...children,
                            ],
                          ),
                          if (footer != null) ...[
                            const SizedBox(height: QaSpacing.xl),
                            footer!,
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Quadrapp',
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontSize: 22, height: 1.2),
    );
  }
}

/// El recuadro menta con un ícono, sobre el titular de la verificación.
class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.qaColors;
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: QaRadii.cardRadius,
        ),
        child: SizedBox.square(
          dimension: 52,
          child: Icon(icon, color: colors.primary, size: 26),
        ),
      ),
    );
  }
}

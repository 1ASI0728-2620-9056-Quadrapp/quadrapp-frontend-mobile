import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_colors.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_radii.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_spacing.dart';

/// El logo de Quadrapp: un cuadrado teal de esquinas redondeadas con un pin de
/// ubicación blanco. Decorativo: el nombre va al lado, como texto.
class QaBrandMark extends StatelessWidget {
  const QaBrandMark({this.size = 36, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.qaColors;
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.primary,
          borderRadius: BorderRadius.circular(size * 0.3),
        ),
        child: SizedBox.square(
          dimension: size,
          child: Icon(
            Icons.location_on_outlined,
            size: size * 0.58,
            color: colors.onPrimary,
          ),
        ),
      ),
    );
  }
}

/// La acción de la derecha de [QaTopBar]: un ícono de 48 dp con su etiqueta
/// (que es también su tooltip y su texto para el lector de pantalla).
class QaTopBarAction {
  const QaTopBarAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
}

/// Barra superior del diseño.
///
/// - **De pestaña** (por defecto): el logo, «Quadrapp», el título de la
///   pestaña y, a la derecha, una acción opcional (el perfil, el filtro...).
///   Con el texto muy grande el nombre de la marca se oculta y queda el logo.
/// - **Con [onBack]** (pantallas a las que se llega desde otra): la flecha de
///   volver y el título.
///
/// Es una fila sobre la superficie, sin sombra; el título es un encabezado
/// semántico.
class QaTopBar extends StatelessWidget {
  const QaTopBar({
    required this.title,
    this.action,
    this.onBack,
    this.backLabel,
    super.key,
  });

  final String title;
  final QaTopBarAction? action;

  /// Con valor, la barra es de «atrás» en lugar de la de pestaña.
  final VoidCallback? onBack;

  /// Etiqueta de la flecha de volver (obligatoria con [onBack] para el lector
  /// de pantalla).
  final String? backLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.qaColors;
    final onBack = this.onBack;
    final action = this.action;
    final largeText = MediaQuery.textScalerOf(context).scale(16) >= 22;

    final titleText = Semantics(
      header: true,
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w400,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: onBack != null ? TextAlign.center : TextAlign.start,
      ),
    );

    final Widget content;
    if (onBack != null) {
      content = Row(
        children: [
          IconButton(
            tooltip: backLabel,
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: onBack,
            style: IconButton.styleFrom(
              minimumSize: const Size.square(QaSpacing.minTapTarget),
            ),
          ),
          Expanded(child: titleText),
          // Mismo ancho que la flecha: el título queda centrado.
          SizedBox(
            width: QaSpacing.minTapTarget,
            child: action == null ? null : _ActionButton(action: action),
          ),
        ],
      );
    } else {
      content = Row(
        children: [
          const QaBrandMark(),
          if (!largeText) ...[
            const SizedBox(width: QaSpacing.sm),
            Text(
              'Quadrapp',
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 20,
                height: 1.2,
              ),
            ),
          ],
          const SizedBox(width: QaSpacing.xl),
          Expanded(child: titleText),
          if (action != null) _ActionButton(action: action),
        ],
      );
    }

    // El fondo cubre también la barra de estado: la barra respeta el inset
    // dentro de su propia superficie.
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.surface),
      child: SafeArea(
        bottom: false,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 64),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: onBack != null ? QaSpacing.xs : QaSpacing.lg,
              vertical: QaSpacing.sm,
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action});

  final QaTopBarAction action;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: action.label,
      icon: Icon(action.icon),
      onPressed: action.onPressed,
      style: IconButton.styleFrom(
        minimumSize: const Size.square(QaSpacing.minTapTarget),
        shape: const RoundedRectangleBorder(
          borderRadius: QaRadii.controlRadius,
        ),
      ),
    );
  }
}

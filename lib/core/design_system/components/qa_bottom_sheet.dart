import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_colors.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_elevation.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_radii.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_spacing.dart';

/// Ancho máximo de la ventana inferior en pantallas grandes.
const double qaBottomSheetMaxWidth = 480;

/// Abre una ventana inferior con el contenido de [builder] (normalmente un
/// [QaBottomSheet]) y devuelve lo que se le pase a `Navigator.pop`.
///
/// Se cierra con un gesto hacia abajo, tocando fuera (si [isDismissible]), con
/// el botón de cerrar o con "atrás". Ocupa como mucho el ancho de
/// [qaBottomSheetMaxWidth], centrada. Al cerrarse, el foco vuelve a donde
/// estaba.
Future<T?> showQaBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isDismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    builder: builder,
    isScrollControlled: true,
    useSafeArea: true,
    isDismissible: isDismissible,
    backgroundColor: Colors.transparent,
    elevation: 0,
    constraints: const BoxConstraints(maxWidth: qaBottomSheetMaxWidth),
  );
}

/// El contenido de una ventana inferior: asa, título con botón de cerrar, un
/// cuerpo que se desplaza y una acción primaria **fija abajo** ([footer]).
///
/// - Sube con el teclado: el cuerpo se desplaza y la acción primaria queda
///   siempre a la vista.
/// - Al abrirse, el foco pasa al título (que se anuncia como encabezado de la
///   ventana); cerrarla lo devuelve a quien la abrió.
/// - El botón de cerrar mide 48 dp y lleva [closeLabel] como etiqueta.
class QaBottomSheet extends StatelessWidget {
  const QaBottomSheet({
    required this.title,
    required this.closeLabel,
    required this.child,
    this.subtitle,
    this.footer,
    super.key,
  });

  final String title;

  /// Una línea bajo el título que dice para qué sirve la ventana.
  final String? subtitle;

  /// Etiqueta accesible del botón de cerrar.
  final String closeLabel;

  /// El cuerpo; se desplaza si no cabe.
  final Widget child;

  /// La acción primaria, fija abajo (un `QaButton` grande).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final colors = context.qaColors;
    final theme = Theme.of(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: Semantics(
        scopesRoute: true,
        namesRoute: true,
        explicitChildNodes: true,
        label: title,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: QaRadii.sheetRadius,
            boxShadow: QaElevation.of(colors, QaElevationLevel.high),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: QaSpacing.sm),
                Center(
                  child: ExcludeSemantics(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colors.paint,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: const SizedBox(width: 40, height: 4),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: QaSpacing.xl,
                    right: QaSpacing.sm,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Focus(
                          autofocus: true,
                          child: Semantics(
                            header: true,
                            child: Text(
                              title,
                              style: theme.textTheme.headlineSmall,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).maybePop(),
                        tooltip: closeLabel,
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          minimumSize: const Size.square(
                            QaSpacing.minTapTarget,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (subtitle case final subtitle?)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      QaSpacing.xl,
                      0,
                      QaSpacing.xl,
                      QaSpacing.sm,
                    ),
                    child: Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceMuted,
                      ),
                    ),
                  ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      QaSpacing.xl,
                      QaSpacing.sm,
                      QaSpacing.xl,
                      QaSpacing.lg,
                    ),
                    child: child,
                  ),
                ),
                if (footer != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      QaSpacing.xl,
                      0,
                      QaSpacing.xl,
                      QaSpacing.lg,
                    ),
                    child: footer,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

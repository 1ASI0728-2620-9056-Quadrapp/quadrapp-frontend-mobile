import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/core/design_system/components/qa_button.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_colors.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_radii.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_spacing.dart';

/// Tipo de aviso de [QaBanner].
enum QaBannerKind {
  /// Sin conexión: se muestra lo último que hay.
  offline,

  /// Datos desactualizados.
  stale,

  /// Información neutra: el panel menta de privacidad y de ayuda.
  info,

  /// Nota de método o de procedencia (fondo azul suave).
  note,

  /// Error recuperable dentro de un formulario o una pantalla (con texto e
  /// ícono; nunca solo color).
  error,
}

/// Aviso de estado del sistema (sin conexión, datos desactualizados). Es un
/// panel de fondo suave sin borde, con el ícono y el texto en el tono del
/// aviso, como en el diseño. Se anuncia como región viva y siempre lleva
/// ícono + texto, no solo color.
///
/// Con [requestFocus] el foco pasa al aviso cada vez que aparece o cambia su
/// mensaje (por ejemplo, un error de formulario): quien usa TalkBack o un
/// teclado externo llega directo al mensaje.
class QaBanner extends StatefulWidget {
  const QaBanner({
    required this.kind,
    required this.message,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.requestFocus = false,
    super.key,
  });

  final QaBannerKind kind;
  final String message;

  /// Sustituye el ícono propio del [kind] (por ejemplo, un escudo en la nota de
  /// privacidad).
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Mueve el foco a este aviso cuando aparece o cambia [message].
  final bool requestFocus;

  @override
  State<QaBanner> createState() => _QaBannerState();
}

class _QaBannerState extends State<QaBanner> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'QaBanner');

  @override
  void initState() {
    super.initState();
    if (widget.requestFocus) _focusSoon();
  }

  @override
  void didUpdateWidget(QaBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.requestFocus && oldWidget.message != widget.message) {
      _focusSoon();
    }
  }

  void _focusSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.kind;
    final message = widget.message;
    final actionLabel = widget.actionLabel;
    final onAction = widget.onAction;
    final colors = context.qaColors;
    final (
      Color background,
      Color foreground,
      IconData kindIcon,
    ) = switch (kind) {
      QaBannerKind.offline => (
        colors.limitedFill,
        colors.limitedText,
        Icons.wifi_off_rounded,
      ),
      QaBannerKind.stale => (
        colors.limitedFill,
        colors.limitedText,
        Icons.history_toggle_off_rounded,
      ),
      QaBannerKind.info => (colors.mint, colors.onMint, Icons.shield_outlined),
      QaBannerKind.note => (
        colors.infoFill,
        colors.onSurface,
        Icons.insights_rounded,
      ),
      QaBannerKind.error => (
        colors.alertFill,
        colors.full,
        Icons.error_outline,
      ),
    };
    final icon = widget.icon ?? kindIcon;

    return Focus(
      focusNode: _focusNode,
      child: Semantics(
        liveRegion: true,
        container: true,
        focusable: widget.requestFocus,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: QaRadii.controlRadius,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: QaSpacing.lg,
              vertical: QaSpacing.md,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Icon(icon, color: foreground, size: 20),
                ),
                const SizedBox(width: QaSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: foreground),
                      ),
                      // La acción va debajo del mensaje: así no se desborda
                      // con el texto al 200 %.
                      if (actionLabel != null && onAction != null)
                        Align(
                          alignment: AlignmentDirectional.centerEnd,
                          child: QaButton(
                            label: actionLabel,
                            onPressed: onAction,
                            variant: QaButtonVariant.text,
                            color: foreground,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

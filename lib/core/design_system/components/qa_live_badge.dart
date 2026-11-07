import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_colors.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_spacing.dart';

/// Estado real de la conexión en tiempo real.
enum QaLiveStatus {
  /// Conectado y recibiendo cambios ("En línea").
  live,

  /// Se perdió la conexión y se está reintentando.
  reconnecting,

  /// Sin conexión: se muestra lo último guardado.
  offline,
}

/// Píldora "En línea" / "Reconectando" / "Sin conexión" del diseño. **Nunca es
/// decorativa:** refleja el estado real de la conexión. Cada estado se
/// distingue por su ícono (señal, señal buscando, señal tachada), por su texto
/// y por su fondo, no solo por el color, y los cambios se anuncian como región
/// viva. No lleva animación: el estado cambia, no parpadea.
class QaLiveBadge extends StatelessWidget {
  const QaLiveBadge({required this.status, required this.label, super.key});

  final QaLiveStatus status;

  /// El texto del estado, ya traducido.
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.qaColors;
    final (Color fill, Color foreground, IconData icon) = switch (status) {
      QaLiveStatus.live => (colors.freeFill, colors.free, Icons.wifi_rounded),
      QaLiveStatus.reconnecting => (
        colors.limitedFill,
        colors.limitedText,
        Icons.wifi_find_rounded,
      ),
      QaLiveStatus.offline => (
        colors.surfaceMuted,
        colors.onSurfaceMuted,
        Icons.wifi_off_rounded,
      ),
    };
    return Semantics(
      container: true,
      liveRegion: true,
      label: label,
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: ShapeDecoration(
            color: fill,
            shape: const StadiumBorder(),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: QaSpacing.md,
              vertical: QaSpacing.xs + 2,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: foreground),
                const SizedBox(width: QaSpacing.xs + 2),
                Flexible(
                  child: Text(
                    label,
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: foreground),
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

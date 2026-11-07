import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';

/// Sección de la galería: un componente con todos sus estados.
class GallerySection extends StatelessWidget {
  const GallerySection({
    required this.title,
    required this.children,
    super.key,
  });

  /// Nombre del componente (identificador de código, no texto de la app).
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: QaSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const SizedBox(height: QaSpacing.md),
          ...children,
        ],
      ),
    );
  }
}

/// Un estado (cargando, vacío, error, parcial, éxito, deshabilitado) de un
/// componente, con su rótulo.
class GalleryState extends StatelessWidget {
  const GalleryState({required this.label, required this.child, super.key});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: QaSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: context.qaColors.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: QaSpacing.sm),
          child,
        ],
      ),
    );
  }
}

/// Superficie con borde donde se muestran los estados vacío y de error, como
/// lo haría una pantalla real.
class GallerySurface extends StatelessWidget {
  const GallerySurface({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.qaColors;
    return SizedBox(
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: QaRadii.cardRadius,
          border: Border.all(color: colors.paint),
        ),
        child: child,
      ),
    );
  }
}

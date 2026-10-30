import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/app/gallery/gallery_parts.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';

/// Relación de contraste WCAG entre dos colores opacos.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// La paleta del modo activo: cada token con su valor, el color de texto que
/// lleva encima y el contraste de ese par. Los nombres son identificadores de
/// código, no textos de la app.
class GalleryPalette extends StatelessWidget {
  const GalleryPalette({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.qaColors;
    final swatches = <(String, Color, Color)>[
      ('primary', c.primary, c.onPrimary),
      ('primaryDark', c.primaryDark, c.onPrimary),
      ('primaryContainer', c.primaryContainer, c.onPrimaryContainer),
      ('brand', c.brand, c.onBrand),
      ('brandAccent', c.brandAccent, c.onBrandAccent),
      ('freeFill', c.freeFill, c.free),
      ('limitedFill', c.limitedFill, c.limitedText),
      ('alertFill', c.alertFill, c.full),
      ('occupiedFill', c.occupiedFill, c.occupied),
      ('mint', c.mint, c.onMint),
      ('infoFill', c.infoFill, c.onSurface),
      ('full', c.full, c.onAccent),
      ('occupied', c.occupied, c.onAccent),
      ('surface', c.surface, c.onSurface),
      ('background', c.background, c.onSurface),
      ('surfaceMuted', c.surfaceMuted, c.onSurfaceMuted),
    ];
    return GallerySection(
      title: 'Palette',
      children: [
        for (final (name, fill, on) in swatches)
          Padding(
            padding: const EdgeInsets.only(bottom: QaSpacing.sm),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: fill,
                borderRadius: QaRadii.controlRadius,
                border: Border.all(color: c.paint),
              ),
              child: Padding(
                padding: const EdgeInsets.all(QaSpacing.md),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: Theme.of(
                          context,
                        ).textTheme.labelLarge?.copyWith(color: on),
                      ),
                    ),
                    Text(
                      '${_contrast(on, fill).toStringAsFixed(2)}:1',
                      style: Theme.of(
                        context,
                      ).textTheme.labelMedium?.copyWith(color: on),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: QaSpacing.md),
        Wrap(
          spacing: QaSpacing.lg,
          runSpacing: QaSpacing.sm,
          children: [
            for (final tone in QaTone.values)
              QaStatusChip(tone: tone, label: tone.name),
          ],
        ),
      ],
    );
  }
}

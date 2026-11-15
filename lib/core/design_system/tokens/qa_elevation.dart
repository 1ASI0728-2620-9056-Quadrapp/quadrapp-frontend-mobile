import 'package:flutter/painting.dart';
import 'package:quadrapp_mobile/core/design_system/tokens/qa_colors.dart';

/// Los dos niveles de elevación de las superficies.
enum QaElevationLevel {
  /// Tarjetas en reposo.
  low,

  /// Lo que flota sobre lo demás: héroes, ventanas inferiores.
  high,
}

/// Sombras de dos capas, muy difusas y teñidas de azul-slate (no gris
/// genérico). En modo oscuro casi no se ven: [QaColors.shadowStrength] las
/// refuerza. La superficie siempre lleva además un borde de 1 dp: la sombra
/// nunca es lo único que la separa del fondo.
abstract final class QaElevation {
  static List<BoxShadow> of(QaColors colors, QaElevationLevel level) {
    Color tint(double alpha) => colors.shadow.withValues(
      alpha: (alpha * colors.shadowStrength).clamp(0.0, 1.0),
    );
    return switch (level) {
      QaElevationLevel.low => [
        BoxShadow(
          color: tint(0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
        BoxShadow(color: tint(0.04), blurRadius: 2, offset: const Offset(0, 1)),
      ],
      QaElevationLevel.high => [
        BoxShadow(
          color: tint(0.14),
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
        BoxShadow(color: tint(0.06), blurRadius: 8, offset: const Offset(0, 2)),
      ],
    };
  }
}

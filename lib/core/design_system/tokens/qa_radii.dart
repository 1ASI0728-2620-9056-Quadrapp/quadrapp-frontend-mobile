import 'package:flutter/painting.dart';

/// Radios con jerarquía: controles (12), tarjetas (20), superficies (24:
/// hojas, ventanas y diálogos) y la placa de llegada (16).
abstract final class QaRadii {
  static const double control = 12;
  static const double card = 20;
  static const double surface = 24;
  static const double plate = 16;

  /// Radio interior de la placa de llegada (dentro de su borde de 2 dp).
  static const double plateInner = 12;

  /// Borde interno de la placa de llegada (como un letrero).
  static const double plateBorderWidth = 2;

  /// Borde de las superficies (se separa por borde, no por sombra).
  static const double surfaceBorderWidth = 1;

  static const BorderRadius controlRadius = BorderRadius.all(
    Radius.circular(control),
  );
  static const BorderRadius cardRadius = BorderRadius.all(
    Radius.circular(card),
  );
  static const BorderRadius surfaceRadius = BorderRadius.all(
    Radius.circular(surface),
  );

  /// Hoja que sube sobre otra zona (por ejemplo, el formulario de acceso):
  /// solo las esquinas superiores.
  static const BorderRadius sheetRadius = BorderRadius.vertical(
    top: Radius.circular(surface),
  );
  static const BorderRadius plateRadius = BorderRadius.all(
    Radius.circular(plate),
  );
}

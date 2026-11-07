import 'package:flutter/widgets.dart';

/// Movimiento: solo como respuesta a una acción o para señalar un cambio real.
abstract final class QaMotion {
  /// Pulso de un espacio que cambia de estado.
  static const Duration pulse = Duration(milliseconds: 400);

  /// Cambios de tamaño de un aviso o de la zona de marca.
  static const Duration resize = Duration(milliseconds: 200);

  /// Cambio de pestaña (fade).
  static const Duration tab = Duration(milliseconds: 200);

  /// Transición fade-through entre las pantallas de acceso.
  static const Duration fadeThrough = Duration(milliseconds: 250);

  /// Las líneas del patrón de marca se dibujan una sola vez al abrir.
  static const Duration brandDraw = Duration(milliseconds: 600);

  /// `duration`, o cero si el usuario desactivó las animaciones.
  static Duration of(BuildContext context, Duration duration) =>
      enabled(context) ? duration : Duration.zero;

  /// Respeta `MediaQuery.disableAnimations` (y el ajuste del sistema).
  static bool enabled(BuildContext context) =>
      !MediaQuery.disableAnimationsOf(context);
}

import 'dart:async';

import 'package:flutter/services.dart';

/// Háptica, solo en confirmaciones (confirmar una acción, completar un
/// registro). Nunca en cada toque.
abstract final class QaHaptics {
  /// Una confirmación ligera.
  static void confirm() => unawaited(HapticFeedback.lightImpact());

  /// Una acción completada.
  static void success() => unawaited(HapticFeedback.mediumImpact());
}

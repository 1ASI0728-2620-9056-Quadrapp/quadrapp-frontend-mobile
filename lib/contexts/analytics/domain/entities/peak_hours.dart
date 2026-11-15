import 'package:equatable/equatable.dart';

/// Una franja del día con ocupación alta (US22 esc. 1), en hora de Lima.
class PeakWindow extends Equatable {
  const PeakWindow({
    required this.startMinute,
    required this.endMinute,
    required this.avgOccupancyPct,
  });

  /// Minutos desde la medianoche (0 a 1439).
  final int startMinute;

  /// Minutos desde la medianoche; mayor que [startMinute].
  final int endMinute;

  /// Ocupación promedio de la franja en el periodo (0 a 100).
  final double avgOccupancyPct;

  @override
  List<Object?> get props => [startMinute, endMinute, avgOccupancyPct];
}

/// Las horas de mayor ocupación de un periodo (US22). Sin datos históricos
/// suficientes no hay franjas y la pantalla lo dice (esc. 3).
class PeakHours extends Equatable {
  PeakHours({required this.sufficientData, required List<PeakWindow> peaks})
    : peaks = sufficientData
          ? List.unmodifiable(
              List<PeakWindow>.of(peaks)..sort(
                (a, b) => b.avgOccupancyPct.compareTo(a.avgOccupancyPct),
              ),
            )
          : const [];

  /// `false`: el periodo no tiene historial suficiente (US22 esc. 3).
  final bool sufficientData;

  /// De mayor a menor ocupación promedio. Vacía si no hay datos suficientes.
  final List<PeakWindow> peaks;

  /// La franja de mayor ocupación.
  PeakWindow? get top => peaks.isEmpty ? null : peaks.first;

  @override
  List<Object?> get props => [sufficientData, peaks];
}

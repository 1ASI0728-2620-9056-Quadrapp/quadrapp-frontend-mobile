import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/analytics/domain/value_objects/analytics_period.dart';
import 'package:quadrapp_mobile/contexts/analytics/domain/value_objects/occupancy_granularity.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

/// La ocupación promedio de un intervalo (una hora o un día) que empieza en
/// [at] (UTC).
class OccupancyPoint extends Equatable {
  const OccupancyPoint({required this.at, required this.occupancyPct});

  final DateTime at;

  /// De 0 a 100. Los espacios sin datos no cuentan como libres (US08).
  final double occupancyPct;

  @override
  List<Object?> get props => [at, occupancyPct];
}

/// El historial de ocupación de un estacionamiento o de una de sus zonas en un
/// rango (US21, TS11 esc. 1).
class OccupancyHistory extends Equatable {
  OccupancyHistory({
    required this.lotId,
    required this.range,
    required this.granularity,
    required List<OccupancyPoint> points,
    required this.serverTime,
    this.zoneId,
  }) : points = List.unmodifiable(
         List<OccupancyPoint>.of(points)..sort((a, b) => a.at.compareTo(b.at)),
       );

  final LotId lotId;

  /// `null` si es todo el estacionamiento (US21 esc. 2).
  final ZoneId? zoneId;
  final AnalyticsRange range;
  final OccupancyGranularity granularity;

  /// En orden cronológico.
  final List<OccupancyPoint> points;

  /// Hora del servidor al responder (UTC): hasta cuándo llegan los datos.
  final DateTime serverTime;

  /// No hay registros en el periodo (US21 esc. 3).
  bool get isEmpty => points.isEmpty;

  /// El intervalo de mayor ocupación (el primero si hay empate).
  OccupancyPoint? get peak {
    OccupancyPoint? top;
    for (final point in points) {
      if (top == null || point.occupancyPct > top.occupancyPct) top = point;
    }
    return top;
  }

  /// El promedio del periodo, o `null` sin registros.
  double? get average {
    if (points.isEmpty) return null;
    final sum = points.fold<double>(0, (total, p) => total + p.occupancyPct);
    return sum / points.length;
  }

  /// El último intervalo con dato.
  OccupancyPoint? get latest => points.isEmpty ? null : points.last;

  @override
  List<Object?> get props => [
    lotId.value,
    zoneId?.value,
    range,
    granularity,
    points,
    serverTime,
  ];
}

// US06
import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/entities/lot_occupancy.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/entities/zone_occupancy.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/services/occupancy_counter.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

/// Parámetros de [GetZoneSummary].
class GetZoneSummaryParams extends Equatable {
  const GetZoneSummaryParams({
    required this.occupancy,
    required this.membership,
  });

  final LotOccupancy occupancy;

  /// Qué espacios tiene cada zona (solo identificadores; viene del layout de
  /// `parking_configuration`).
  final Map<ZoneId, List<SpaceId>> membership;

  @override
  List<Object?> get props => [occupancy, membership];
}

/// Conteo de libres, ocupados y desconocidos por zona. Los desconocidos se
/// informan aparte y nunca cuentan como libres (US06 esc. 3).
class GetZoneSummary {
  const GetZoneSummary([this._counter = const OccupancyCounter()]);

  final OccupancyCounter _counter;

  List<ZoneOccupancy> call(GetZoneSummaryParams params) =>
      _counter.byZone(params.occupancy.spaces, params.membership);
}

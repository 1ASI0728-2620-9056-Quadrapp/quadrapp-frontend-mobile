// US06
import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/entities/level_occupancy.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/entities/lot_occupancy.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/services/occupancy_counter.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

/// Parámetros de [GetLevelSummary].
class GetLevelSummaryParams extends Equatable {
  const GetLevelSummaryParams({
    required this.occupancy,
    required this.membership,
  });

  final LotOccupancy occupancy;

  /// Qué espacios tiene cada nivel (solo identificadores; viene del layout de
  /// `parking_configuration`).
  final Map<LevelId, List<SpaceId>> membership;

  @override
  List<Object?> get props => [occupancy, membership];
}

/// Conteo de libres, ocupados y desconocidos por nivel. Los desconocidos se
/// informan aparte y nunca cuentan como libres (US06 esc. 3, US08 esc. 3).
class GetLevelSummary {
  const GetLevelSummary([this._counter = const OccupancyCounter()]);

  final OccupancyCounter _counter;

  List<LevelOccupancy> call(GetLevelSummaryParams params) =>
      _counter.byLevel(params.occupancy.spaces, params.membership);
}

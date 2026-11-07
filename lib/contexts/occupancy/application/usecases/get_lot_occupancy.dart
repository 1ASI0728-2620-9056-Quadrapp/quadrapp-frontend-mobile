// US04, US05
import 'package:quadrapp_mobile/contexts/occupancy/domain/entities/lot_occupancy.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/repositories/occupancy_reader.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

/// Consulta la ocupación actual de un estacionamiento.
class GetLotOccupancy implements UseCase<LotOccupancy, LotId> {
  const GetLotOccupancy(this._reader);

  final OccupancyReader _reader;

  @override
  Future<Result<LotOccupancy>> call(LotId lotId) => _reader.read(lotId);
}

// US04
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/entities/parking_lot.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/repositories/parking_lot_reader.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

/// Lista los estacionamientos de la institución. Una lista vacía significa que
/// no hay estacionamientos registrados (US04 esc. 3).
class ListParkingLots implements UseCase<List<ParkingLot>, NoParams> {
  const ListParkingLots(this._reader);

  final ParkingLotReader _reader;

  @override
  Future<Result<List<ParkingLot>>> call(NoParams params) => _reader.list();
}

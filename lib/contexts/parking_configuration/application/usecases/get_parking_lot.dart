// US04
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/entities/parking_lot.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/repositories/parking_lot_reader.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

/// Un estacionamiento (con las coordenadas de destino para el ETA).
class GetParkingLot implements UseCase<ParkingLot, LotId> {
  const GetParkingLot(this._reader);

  final ParkingLotReader _reader;

  @override
  Future<Result<ParkingLot>> call(LotId lotId) => _reader.get(lotId);
}

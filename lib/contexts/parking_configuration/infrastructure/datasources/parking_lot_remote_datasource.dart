import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/dto/parking_lot_dto.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

/// Origen remoto de los estacionamientos (HTTP o mock).
abstract interface class ParkingLotRemoteDataSource {
  Future<List<ParkingLotDto>> list();

  Future<ParkingLotDto> get(LotId lotId);
}

import 'package:quadrapp_mobile/contexts/parking_configuration/domain/entities/parking_lot.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// Lectura de los estacionamientos de la institución (US04).
abstract interface class ParkingLotReader {
  /// Los estacionamientos de la institución del usuario (la institución sale
  /// del token, nunca de un parámetro).
  Future<Result<List<ParkingLot>>> list();

  /// Un estacionamiento; `NotFoundFailure` si no existe.
  Future<Result<ParkingLot>> get(LotId lotId);
}

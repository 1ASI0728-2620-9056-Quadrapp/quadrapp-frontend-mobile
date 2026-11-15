import 'package:quadrapp_mobile/contexts/occupancy/domain/entities/lot_occupancy.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// Lectura de la ocupación actual de un estacionamiento (US05).
// ignore: one_member_abstracts
abstract interface class OccupancyReader {
  /// Red primero; si falla por red, devuelve la última copia guardada marcada
  /// como caché (TS13). Un estacionamiento sin datos vigentes es
  /// `NotFoundFailure` (US04 esc. 2).
  Future<Result<LotOccupancy>> read(LotId lotId);
}

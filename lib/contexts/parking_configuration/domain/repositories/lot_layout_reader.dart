import 'package:quadrapp_mobile/contexts/parking_configuration/domain/entities/lot_layout.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// Lectura de la distribución de un estacionamiento (TS13).
// ignore: one_member_abstracts
abstract interface class LotLayoutReader {
  /// Pide la distribución con la versión que ya se tiene: si no cambió, el
  /// servidor responde 304 y se conserva la copia local. Sin conexión devuelve
  /// la copia local si existe.
  Future<Result<LotLayout>> read(LotId lotId);
}

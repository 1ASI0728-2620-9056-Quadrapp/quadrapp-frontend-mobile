// US29, TS17
import 'package:quadrapp_mobile/composition/shift/shift_overview.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

/// Lectura del estado de operación de un estacionamiento (TS17).
// ignore: one_member_abstracts
abstract interface class ShiftOverviewReader {
  /// `ForbiddenFailure` si la sesión es de un conductor (403, TS17 esc. 2);
  /// `NotFoundFailure` si el estacionamiento no existe o no tiene distribución
  /// publicada.
  Future<Result<ShiftOverview>> read(LotId lotId);
}

/// El estado de operación de un estacionamiento durante el turno.
class GetShiftOverview implements UseCase<ShiftOverview, LotId> {
  const GetShiftOverview(this._reader);

  final ShiftOverviewReader _reader;

  @override
  Future<Result<ShiftOverview>> call(LotId lotId) => _reader.read(lotId);
}

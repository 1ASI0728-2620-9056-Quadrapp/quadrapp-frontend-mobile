// docs/05 regla 7
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/repositories/selected_lot_store.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/network/failure_mapper.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

/// El estacionamiento elegido antes, o `null` si no hay ninguno. Es de mejor
/// esfuerzo para quien lo llama: Inicio lo usa para decidir su lote principal
/// y, si no se puede leer, sigue con el primero de la lista.
class GetSelectedLot implements UseCase<LotId?, NoParams> {
  const GetSelectedLot(this._store);

  final SelectedLotStore _store;

  @override
  Future<Result<LotId?>> call(NoParams params) => guardResult(_store.read);
}

// docs/05 regla 7
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/repositories/selected_lot_store.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/network/failure_mapper.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

/// Recuerda el estacionamiento elegido.
class SelectLot implements UseCase<void, LotId> {
  const SelectLot(this._store);

  final SelectedLotStore _store;

  @override
  Future<Result<void>> call(LotId lotId) =>
      guardResult(() => _store.save(lotId));
}

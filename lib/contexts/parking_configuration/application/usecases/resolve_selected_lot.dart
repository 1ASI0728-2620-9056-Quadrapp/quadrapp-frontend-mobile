// docs/04 (navegación), docs/05 regla 7
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/entities/parking_lot.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/repositories/parking_lot_reader.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/repositories/selected_lot_store.dart';
import 'package:quadrapp_mobile/core/network/failure_mapper.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

/// Decide qué estacionamiento usar en pantallas que lo necesitan sin haberlo
/// recibido (la pestaña "Mapa"):
/// 1. el elegido antes, si todavía existe;
/// 2. si la institución tiene **uno solo**, ese (y queda elegido);
/// 3. en otro caso, `null`: la pantalla muestra "Elegir estacionamiento".
class ResolveSelectedLot implements UseCase<ParkingLot?, NoParams> {
  const ResolveSelectedLot({
    required this._reader,
    required this._store,
  });

  final ParkingLotReader _reader;
  final SelectedLotStore _store;

  @override
  Future<Result<ParkingLot?>> call(NoParams params) async {
    final listed = await _reader.list();
    return listed.fold((lots) async {
      return guardResult(() async {
        final savedId = await _store.read();
        for (final lot in lots) {
          if (lot.id == savedId) return lot;
        }
        if (lots.length == 1) {
          await _store.save(lots.single.id);
          return lots.single;
        }
        if (savedId != null) await _store.clear();
        return null;
      });
    }, (failure) async => Err<ParkingLot?>(failure));
  }
}

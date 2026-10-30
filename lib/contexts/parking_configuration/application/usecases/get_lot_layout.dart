// US06, TS13
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/entities/lot_layout.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/repositories/lot_layout_reader.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

/// La distribución (zonas y espacios) de un estacionamiento.
class GetLotLayout implements UseCase<LotLayout, LotId> {
  const GetLotLayout(this._reader);

  final LotLayoutReader _reader;

  @override
  Future<Result<LotLayout>> call(LotId lotId) => _reader.read(lotId);
}

// US29, TS17
import 'package:quadrapp_mobile/composition/shift/get_shift_overview.dart';
import 'package:quadrapp_mobile/composition/shift/shift_overview.dart';
import 'package:quadrapp_mobile/composition/shift/shift_overview_mapper.dart';
import 'package:quadrapp_mobile/composition/shift/shift_overview_remote_datasource.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/network/failure_mapper.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';

/// Lee el estado de operación y convierte cualquier falla de infraestructura
/// en una `Failure`. Sin caché: es una consulta operativa que solo vale si es
/// actual.
class ShiftOverviewReaderImpl implements ShiftOverviewReader {
  const ShiftOverviewReaderImpl({
    required this._remote,
    required this._mapper,
    required this._clock,
  });

  final ShiftOverviewRemoteDataSource _remote;
  final ShiftOverviewMapper _mapper;
  final Clock _clock;

  @override
  Future<Result<ShiftOverview>> read(LotId lotId) => guardResult(() async {
    final dto = await _remote.fetch(lotId);
    return _mapper.toEntity(dto, receivedAt: _clock.monotonic());
  });
}

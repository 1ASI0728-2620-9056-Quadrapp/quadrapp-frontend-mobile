// US19, US29
import 'package:quadrapp_mobile/composition/accesses/accesses_overview.dart';
import 'package:quadrapp_mobile/composition/accesses/accesses_overview_mapper.dart';
import 'package:quadrapp_mobile/composition/accesses/accesses_overview_remote_datasource.dart';
import 'package:quadrapp_mobile/composition/accesses/get_accesses_overview.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/network/failure_mapper.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';

/// Lee los accesos y convierte cualquier falla de infraestructura en una
/// `Failure`. Sin caché: el flujo solo vale si es actual.
class AccessesOverviewReaderImpl implements AccessesOverviewReader {
  const AccessesOverviewReaderImpl({
    required this._remote,
    required this._mapper,
    required this._clock,
  });

  final AccessesOverviewRemoteDataSource _remote;
  final AccessesOverviewMapper _mapper;
  final Clock _clock;

  @override
  Future<Result<AccessesOverview>> read(LotId lotId) => guardResult(() async {
    final dto = await _remote.fetch(lotId);
    return _mapper.toEntity(dto, receivedAt: _clock.monotonic());
  });
}

import 'package:quadrapp_mobile/contexts/occupancy/domain/entities/lot_occupancy.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/repositories/occupancy_reader.dart';
import 'package:quadrapp_mobile/contexts/occupancy/infrastructure/datasources/occupancy_cache_datasource.dart';
import 'package:quadrapp_mobile/contexts/occupancy/infrastructure/datasources/occupancy_remote_datasource.dart';
import 'package:quadrapp_mobile/contexts/occupancy/infrastructure/mappers/occupancy_mapper.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/network/failure_mapper.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';

/// Política de repositorio (TS13): red primero; si falla **por red**, devuelve
/// la última copia guardada marcada como caché. Cualquier otro error se
/// devuelve tal cual (una copia vieja no tapa un 401 ni un 404).
class OccupancyReaderImpl implements OccupancyReader {
  const OccupancyReaderImpl({
    required this._remote,
    required this._cache,
    required this._mapper,
    required this._clock,
  });

  final OccupancyRemoteDataSource _remote;
  final OccupancyCacheDataSource _cache;
  final OccupancyMapper _mapper;
  final Clock _clock;

  @override
  Future<Result<LotOccupancy>> read(LotId lotId) async {
    final fresh = await guardResult(() async {
      final dto = await _remote.fetch(lotId);
      final occupancy = _mapper.toEntity(
        dto,
        lotId,
        receivedAt: _clock.monotonic(),
      );
      try {
        await _cache.write(lotId, dto, _clock.now());
      } on Object {
        // Una caché que no se puede escribir no debe fallar la consulta.
      }
      return occupancy;
    });

    if (fresh.failureOrNull is! NetworkFailure) return fresh;

    final cached = await _cache.read(lotId);
    if (cached == null) return fresh;
    return guardResult(
      () async => _mapper.toEntity(
        cached.dto,
        lotId,
        storedAt: cached.storedAt,
        source: OccupancySource.cache,
      ),
    );
  }
}

import 'package:quadrapp_mobile/contexts/parking_configuration/domain/entities/lot_layout.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/repositories/lot_layout_reader.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/datasources/lot_layout_cache_datasource.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/datasources/lot_layout_remote_datasource.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/mappers/parking_configuration_mapper.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/network/failure_mapper.dart';
import 'package:quadrapp_mobile/core/network/parse_exception.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// Distribución con caché versionada (TS13): se pide con la versión guardada;
/// un 304 conserva la copia local; sin conexión se devuelve la copia local.
class LotLayoutReaderImpl implements LotLayoutReader {
  const LotLayoutReaderImpl({
    required this._remote,
    required this._cache,
    this._mapper = const ParkingConfigurationMapper(),
  });

  final LotLayoutRemoteDataSource _remote;
  final LotLayoutCacheDataSource _cache;
  final ParkingConfigurationMapper _mapper;

  @override
  Future<Result<LotLayout>> read(LotId lotId) async {
    final cached = await _cache.read(lotId);

    final fresh = await guardResult(() async {
      final fetch = await _remote.fetch(lotId, knownVersion: cached?.version);
      switch (fetch) {
        case LayoutNotModified():
          if (cached == null) {
            // El servidor respondió 304 sin que se hubiera enviado una versión:
            // el contrato no se está cumpliendo.
            throw const ParseException(
              '304 sin copia local de la distribución.',
            );
          }
          return _mapper.toLayout(cached, lotId);
        case LayoutFetched(:final dto):
          try {
            await _cache.write(lotId, dto);
          } on Object {
            // Una caché que no se puede escribir no debe fallar la consulta.
          }
          return _mapper.toLayout(dto, lotId);
      }
    });

    if (fresh.failureOrNull is NetworkFailure && cached != null) {
      return guardResult(() async => _mapper.toLayout(cached, lotId));
    }
    return fresh;
  }
}

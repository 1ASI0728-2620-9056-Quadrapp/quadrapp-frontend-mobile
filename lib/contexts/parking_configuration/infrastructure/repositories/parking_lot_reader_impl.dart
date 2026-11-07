import 'package:quadrapp_mobile/contexts/parking_configuration/domain/entities/parking_lot.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/repositories/parking_lot_reader.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/datasources/parking_lot_remote_datasource.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/mappers/parking_configuration_mapper.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/network/failure_mapper.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// Lee los estacionamientos del servidor y convierte cualquier falla de
/// infraestructura en una `Failure` (US04). No tiene caché: solo el layout y la
/// última ocupación se guardan para uso sin conexión (TS13).
class ParkingLotReaderImpl implements ParkingLotReader {
  const ParkingLotReaderImpl({
    required this._remote,
    this._mapper = const ParkingConfigurationMapper(),
  });

  final ParkingLotRemoteDataSource _remote;
  final ParkingConfigurationMapper _mapper;

  @override
  Future<Result<List<ParkingLot>>> list() => guardResult(() async {
    final dtos = await _remote.list();
    return dtos.map(_mapper.toLot).toList();
  });

  @override
  Future<Result<ParkingLot>> get(LotId lotId) =>
      guardResult(() async => _mapper.toLot(await _remote.get(lotId)));
}

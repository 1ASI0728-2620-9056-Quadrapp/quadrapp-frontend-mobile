import 'package:quadrapp_mobile/contexts/parking_configuration/domain/repositories/lot_settings_writer.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/value_objects/lot_settings.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/datasources/lot_settings_datasource.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/mappers/lot_settings_mapper.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/network/failure_mapper.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// Guarda con el origen remoto y convierte cualquier falla en una `Failure`.
class LotSettingsWriterImpl implements LotSettingsWriter {
  const LotSettingsWriterImpl({required this._remote, required this._mapper});

  final LotSettingsRemoteDataSource _remote;
  final LotSettingsMapper _mapper;

  @override
  Future<Result<LotSettings>> update(LotId lotId, LotSettings settings) =>
      guardResult(() async {
        final saved = await _remote.update(lotId, _mapper.toDto(settings));
        return _mapper.toEntity(saved);
      });
}

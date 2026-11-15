// US19, US29
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/repositories/lot_settings_writer.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/value_objects/lot_settings.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

/// El estacionamiento y su nueva configuración.
typedef UpdateLotSettingsParams = ({LotId lotId, LotSettings settings});

/// Guarda el horario y la alerta de ocupación de un estacionamiento. La
/// configuración ya llega validada ([LotSettings.create]); devuelve la que
/// quedó en el servidor, que es la fuente de verdad.
class UpdateLotSettings
    implements UseCase<LotSettings, UpdateLotSettingsParams> {
  const UpdateLotSettings(this._writer);

  final LotSettingsWriter _writer;

  @override
  Future<Result<LotSettings>> call(UpdateLotSettingsParams params) =>
      _writer.update(params.lotId, params.settings);
}

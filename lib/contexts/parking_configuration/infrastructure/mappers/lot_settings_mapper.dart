// US19
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/value_objects/lot_settings.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/dto/lot_settings_dto.dart';
import 'package:quadrapp_mobile/core/logging/logger.dart';

/// DTO <-> [LotSettings]. Lo que llega del servidor no rompe la pantalla
/// ([LotSettings.tolerant]); si hubo que ajustarlo, deja un aviso sin datos
/// personales.
class LotSettingsMapper {
  const LotSettingsMapper(this._logger);

  final Logger _logger;

  LotSettings toEntity(LotSettingsDto dto) {
    final read = LotSettings.tolerant(
      opensAt: LotTime.parse(dto.opensAt),
      closesAt: LotTime.parse(dto.closesAt),
      saturationThresholdPct: dto.saturationThresholdPct,
    );
    if (read.adjusted) {
      _logger.warning(
        'Configuración del estacionamiento no válida '
        '(${dto.opensAt}–${dto.closesAt}, ${dto.saturationThresholdPct} %): '
        'se muestra sin horario y con el umbral en rango',
      );
    }
    return read.settings;
  }

  LotSettingsDto toDto(LotSettings settings) => LotSettingsDto(
    opensAt: settings.opensAt?.hhmm,
    closesAt: settings.closesAt?.hhmm,
    saturationThresholdPct: settings.saturationThresholdPct,
  );
}

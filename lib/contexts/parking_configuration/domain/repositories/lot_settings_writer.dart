import 'package:quadrapp_mobile/contexts/parking_configuration/domain/value_objects/lot_settings.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// Guarda la configuración propia de un estacionamiento
/// (`PATCH /parking-lots/{lotId}`, US19).
// ignore: one_member_abstracts
abstract interface class LotSettingsWriter {
  /// La configuración guardada, tal como quedó en el servidor.
  /// `ForbiddenFailure` si el rol no puede editarla (solo `ADMIN`);
  /// `ValidationFailure` si el servidor rechaza algún campo.
  Future<Result<LotSettings>> update(LotId lotId, LotSettings settings);
}

import 'package:quadrapp_mobile/contexts/notifications/domain/entities/push_message.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/logging/logger.dart';

/// Convierte el `data` de un mensaje push (`{ type, lotId }`, docs/07) en un
/// [PushMessage]. Lo usarán todas las implementaciones de `PushGateway`.
///
/// FCM entrega todos los valores como texto, así que `lotId` llega como
/// `"1"`. Un `type` desconocido o un `lotId` que no es un número positivo dan
/// `null`: el mensaje se ignora y no navega a ninguna parte. Se deja un aviso
/// sin datos personales.
class PushMessageMapper {
  const PushMessageMapper(this._logger);

  final Logger _logger;

  PushMessage? fromData(Map<String, Object?> data) {
    final type = switch ('${data['type']}'.toUpperCase()) {
      'SATURATION' => PushMessageType.saturation,
      'LOW_ARRIVAL' => PushMessageType.lowArrival,
      _ => null,
    };
    final lotId = int.tryParse('${data['lotId']}');
    if (type == null || lotId == null || lotId <= 0) {
      _logger.warning('Mensaje push ignorado: tipo o estacionamiento inválido');
      return null;
    }
    return PushMessage(type: type, lotId: LotId(lotId));
  }
}

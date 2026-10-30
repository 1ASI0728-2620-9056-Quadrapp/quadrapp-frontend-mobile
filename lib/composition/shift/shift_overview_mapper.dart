// US29, TS17
import 'package:quadrapp_mobile/composition/shift/shift_overview.dart';
import 'package:quadrapp_mobile/composition/shift/shift_overview_dto.dart';
import 'package:quadrapp_mobile/contexts/occupancy/occupancy.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/logging/logger.dart';

/// DTO -> [ShiftOverview]. Una sección no disponible que la app no conoce se
/// ignora y deja un aviso (sin datos personales); no rompe la pantalla.
class ShiftOverviewMapper {
  const ShiftOverviewMapper(this._logger);

  final Logger _logger;

  /// [receivedAt] es la lectura del reloj monótono al recibir la respuesta.
  ShiftOverview toEntity(ShiftOverviewDto dto, {required Duration receivedAt}) {
    final unavailable = <ShiftSection>{};
    for (final raw in dto.unavailable) {
      switch (raw.toLowerCase()) {
        case 'saturation':
          unavailable.add(ShiftSection.saturation);
        case 'flow':
          unavailable.add(ShiftSection.flow);
        default:
          _logger.warning('Sección de consola no reconocida "$raw": se ignora');
      }
    }
    final flow = dto.flow;
    final saturation = dto.saturation;
    return ShiftOverview(
      lotId: LotId(dto.lotId),
      capacity: dto.capacity,
      free: dto.free,
      occupied: dto.occupied,
      unknown: dto.unknown,
      freshness: Freshness(
        consolidatedAt: dto.consolidatedAt.toUtc(),
        serverTime: dto.serverTime.toUtc(),
        staleAfter: Duration(seconds: dto.staleAfterSeconds),
        receivedAt: receivedAt,
      ),
      flow: flow == null || unavailable.contains(ShiftSection.flow)
          ? null
          : ShiftFlow(
              entries: flow.entries,
              exits: flow.exits,
              window: Duration(minutes: flow.windowMin),
            ),
      saturation:
          saturation == null || unavailable.contains(ShiftSection.saturation)
          ? null
          : ShiftSaturation(
              expectedAt: saturation.expectedAt.toUtc(),
              pct: saturation.pct,
            ),
      unavailable: unavailable,
    );
  }
}

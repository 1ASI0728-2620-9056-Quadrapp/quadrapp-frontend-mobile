// US19, US29
import 'package:quadrapp_mobile/composition/accesses/accesses_overview.dart';
import 'package:quadrapp_mobile/composition/accesses/accesses_overview_dto.dart';
import 'package:quadrapp_mobile/contexts/occupancy/occupancy.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/logging/logger.dart';

/// DTO -> [AccessesOverview]. Un valor que la app no conoce no rompe la
/// pantalla: un tipo de acceso desconocido es «entrada y salida», un estado
/// desconocido es «sin señal» (el lado cauteloso) y una sección no disponible
/// desconocida se ignora. Cada caso deja un aviso sin datos personales.
class AccessesOverviewMapper {
  const AccessesOverviewMapper(this._logger);

  final Logger _logger;

  /// [receivedAt] es la lectura del reloj monótono al recibir la respuesta.
  AccessesOverview toEntity(
    AccessesOverviewDto dto, {
    required Duration receivedAt,
  }) {
    var flowUnavailable = false;
    for (final raw in dto.unavailable) {
      if (raw.toLowerCase() == 'flow') {
        flowUnavailable = true;
      } else {
        _logger.warning('Sección de accesos no reconocida "$raw": se ignora');
      }
    }

    final settings = LotSettings.tolerant(
      opensAt: LotTime.parse(dto.settings.opensAt),
      closesAt: LotTime.parse(dto.settings.closesAt),
      saturationThresholdPct: dto.settings.saturationThresholdPct,
    );
    if (settings.adjusted) {
      _logger.warning(
        'Configuración del estacionamiento no válida: se muestra sin horario '
        'y con el umbral en rango',
      );
    }

    final flow = dto.flow;
    final accesses = [for (final access in dto.accesses) _access(access)]
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return AccessesOverview(
      lotId: LotId(dto.lotId),
      settings: settings.settings,
      freshness: Freshness(
        consolidatedAt: dto.consolidatedAt.toUtc(),
        serverTime: dto.serverTime.toUtc(),
        staleAfter: Duration(seconds: dto.staleAfterSeconds),
        receivedAt: receivedAt,
      ),
      flowUnavailable: flowUnavailable,
      flow: flow == null || flowUnavailable
          ? null
          : AccessFlow(
              entries: flow.entries,
              exits: flow.exits,
              window: Duration(minutes: flow.windowMin),
              minutes: [
                for (final minute in flow.series)
                  FlowMinute(
                    start: minute.minuteStart.toUtc(),
                    entries: minute.entries,
                    exits: minute.exits,
                  ),
              ]..sort((a, b) => a.start.compareTo(b.start)),
            ),
      accesses: accesses,
    );
  }

  VehicleAccess _access(VehicleAccessDto dto) {
    final type = switch (dto.type.toUpperCase()) {
      'ENTRY' => AccessType.entry,
      'EXIT' => AccessType.exit,
      'BIDIRECTIONAL' => AccessType.bidirectional,
      _ => _unknownType(dto.type),
    };
    final status = switch (dto.status.toUpperCase()) {
      'OPERATIONAL' => AccessStatus.operational,
      'UNREACHABLE' => AccessStatus.unreachable,
      'NOT_COUNTING' => AccessStatus.notCounting,
      _ => _unknownStatus(dto.status),
    };
    // Sin conteo no hay cifras, aunque lleguen.
    final counts =
        dto.flowCountingEnabled && status != AccessStatus.notCounting;
    return VehicleAccess(
      id: AccessId(dto.id),
      name: dto.name,
      type: type,
      status: dto.flowCountingEnabled ? status : AccessStatus.notCounting,
      flowCountingEnabled: dto.flowCountingEnabled,
      entries: counts ? dto.entries : null,
      exits: counts ? dto.exits : null,
    );
  }

  AccessType _unknownType(String raw) {
    _logger.warning('Tipo de acceso no reconocido "$raw": entrada y salida');
    return AccessType.bidirectional;
  }

  AccessStatus _unknownStatus(String raw) {
    _logger.warning('Estado de acceso no reconocido "$raw": sin señal');
    return AccessStatus.unreachable;
  }
}

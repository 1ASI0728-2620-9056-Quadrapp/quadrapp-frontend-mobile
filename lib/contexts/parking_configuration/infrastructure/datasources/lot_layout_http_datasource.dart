import 'package:dio/dio.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/datasources/backend_json.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/datasources/lot_layout_remote_datasource.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/datasources/parking_lot_http_datasource.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/dto/lot_layout_dto.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

/// La distribución armada con las rutas del backend, que no tiene un
/// `/layout` único:
/// `GET /parking-lots/{id}` (versión), `GET /parking-lots/{id}/zones`,
/// `GET /zones/{id}/levels` y `GET /levels/{id}/spaces`.
///
/// El backend todavía no publica versiones de la distribución (todo
/// estacionamiento queda en `layoutVersion` 0 aunque cambien sus zonas), así
/// que la copia local no se da por vigente: siempre se pide entera. Las zonas
/// y los niveles van en su `sortOrder`; los espacios inactivos no se muestran.
class LotLayoutHttpDataSource implements LotLayoutRemoteDataSource {
  const LotLayoutHttpDataSource(this._dio);

  final Dio _dio;

  @override
  Future<LayoutFetch> fetch(LotId lotId, {int? knownVersion}) async {
    final lot = backendObject(
      (await _dio.get<Object?>('/parking-lots/${lotId.value}')).data,
      'El estacionamiento',
    );
    final zones = _sorted(
      await _list('/parking-lots/${lotId.value}/zones', 'Las zonas'),
    );
    return LayoutFetched(
      LotLayoutDto(
        version: effectiveLayoutVersion(backendInt(lot, 'layoutVersion')),
        zones: await Future.wait([for (final zone in zones) _zone(zone)]),
      ),
    );
  }

  Future<ZoneDto> _zone(Map<String, dynamic> zone) async {
    final id = backendInt(zone, 'id');
    final levels = _sorted(await _list('/zones/$id/levels', 'Los niveles'));
    final description = zone['description'];
    return ZoneDto(
      id: id,
      name: zone['name'] as String? ?? '',
      description: description is String ? description : null,
      levels: await Future.wait([for (final level in levels) _level(level)]),
    );
  }

  Future<LevelDto> _level(Map<String, dynamic> level) async {
    final id = backendInt(level, 'id');
    final spaces = await _list('/levels/$id/spaces', 'Los espacios');
    return LevelDto(
      id: id,
      name: level['name'] as String? ?? '',
      spaces: [
        for (final space in spaces)
          if (space['active'] != false)
            SpaceDto(
              id: backendInt(space, 'id'),
              label: space['label'] as String? ?? '',
              posX: (space['posX'] as num?)?.toDouble(),
              posY: (space['posY'] as num?)?.toDouble(),
            ),
      ],
    );
  }

  Future<List<Map<String, dynamic>>> _list(String path, String what) async =>
      backendObjects((await _dio.get<Object?>(path)).data, what);

  static List<Map<String, dynamic>> _sorted(
    List<Map<String, dynamic>> items,
  ) => [...items]
    ..sort(
      (a, b) => ((a['sortOrder'] as num?) ?? 0).compareTo(
        (b['sortOrder'] as num?) ?? 0,
      ),
    );
}

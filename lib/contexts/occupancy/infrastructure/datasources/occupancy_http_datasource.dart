import 'package:dio/dio.dart';
import 'package:quadrapp_mobile/contexts/occupancy/infrastructure/datasources/occupancy_remote_datasource.dart';
import 'package:quadrapp_mobile/contexts/occupancy/infrastructure/dto/lot_occupancy_dto.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/network/parse_exception.dart';

/// La ocupación de un estacionamiento armada con las rutas del backend:
/// - `GET /parking-lots/{id}/occupancy` → `OccupancySummaryResource`
///   (`totalSpaces`, `freeCount`, `occupiedCount`, `unknownCount`, `takenAt`);
/// - `GET /parking-lots/{id}/zones` y `GET /zones/{id}/occupancy` → el conteo
///   por zona;
/// - `GET /parking-lots/{id}` → `staleAfterSeconds`.
///
/// - `GET /parking-lots/{id}/spaces/status` → el estado de cada espacio
///   activo (`spaceId`, `status`, `unknownReason`), para el mapa y los
///   conteos por nivel. Un backend sin esa ruta (404 solo en ella) deja
///   `spaces` vacío y los pabellones usan el conteo por zona del servidor.
///
/// `takenAt` es la hora del servidor al responder, así que vale también como
/// `serverTime`.
class OccupancyHttpDataSource implements OccupancyRemoteDataSource {
  const OccupancyHttpDataSource(this._dio);

  final Dio _dio;

  @override
  Future<LotOccupancyDto> fetch(LotId lotId) async {
    final base = '/parking-lots/${lotId.value}';
    final [lotData, summaryData, zonesData, spacesData] = await Future.wait([
      _get(base),
      _get('$base/occupancy'),
      _get('$base/zones'),
      _spaceStatuses(base),
    ]);
    final lot = _object(lotData, 'El estacionamiento');
    final summary = _object(summaryData, 'La ocupación');
    if (zonesData is! List<dynamic>) {
      throw const ParseException('Las zonas no son un arreglo.');
    }
    final zoneIds = [
      for (final zone in zonesData) _int(_object(zone, 'La zona'), 'id'),
    ];
    final zoneSummaries = await Future.wait([
      for (final id in zoneIds) _get('/zones/$id/occupancy'),
    ]);
    final takenAt = _instant(summary, 'takenAt');
    return LotOccupancyDto(
      capacity: _int(summary, 'totalSpaces'),
      free: _int(summary, 'freeCount'),
      occupied: _int(summary, 'occupiedCount'),
      unknown: _int(summary, 'unknownCount'),
      consolidatedAt: takenAt,
      serverTime: takenAt,
      staleAfterSeconds: _int(lot, 'staleAfterSeconds'),
      zones: [
        for (var i = 0; i < zoneIds.length; i++)
          _zone(zoneIds[i], _object(zoneSummaries[i], 'La zona')),
      ],
      spaces: [
        for (final space in _list(spacesData, 'Los espacios'))
          _space(_object(space, 'El espacio')),
      ],
    );
  }

  /// `SpaceStatusResource[]`; una lista vacía si el backend no tiene la ruta.
  Future<Object?> _spaceStatuses(String base) async {
    try {
      return await _get('$base/spaces/status');
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        // ¿El estacionamiento no existe? Entonces el resumen también da 404.
        return const <Object?>[];
      }
      rethrow;
    }
  }

  static SpaceStateDto _space(Map<String, dynamic> json) {
    final status = json['status'];
    final reason = json['unknownReason'];
    if (status is! String) {
      throw const ParseException('El campo status no es válido.');
    }
    return SpaceStateDto(
      id: _int(json, 'spaceId'),
      status: status,
      unknownReason: reason is String ? reason : null,
    );
  }

  static List<dynamic> _list(Object? data, String what) {
    if (data is! List<dynamic>) {
      throw ParseException('$what no son un arreglo.');
    }
    return data;
  }

  Future<Object?> _get(String path) async =>
      (await _dio.get<Object?>(path)).data;

  static ZoneOccupancyDto _zone(int id, Map<String, dynamic> summary) =>
      ZoneOccupancyDto(
        id: id,
        free: _int(summary, 'freeCount'),
        occupied: _int(summary, 'occupiedCount'),
        unknown: _int(summary, 'unknownCount'),
      );

  static Map<String, dynamic> _object(Object? data, String what) {
    if (data is! Map<String, dynamic>) {
      throw ParseException('$what no es un objeto JSON.');
    }
    return data;
  }

  static int _int(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is! num) throw ParseException('El campo $field no es válido.');
    return value.toInt();
  }

  static DateTime _instant(Map<String, dynamic> json, String field) {
    final value = json[field];
    final parsed = value is String ? DateTime.tryParse(value) : null;
    if (parsed == null) throw ParseException('El campo $field no es válido.');
    return parsed;
  }
}

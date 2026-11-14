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
/// `takenAt` es la hora del servidor al responder, así que vale también como
/// `serverTime`. El backend no expone por REST el estado de cada espacio:
/// `spaces` llega vacío y el mapa por espacio queda «sin datos».
class OccupancyHttpDataSource implements OccupancyRemoteDataSource {
  const OccupancyHttpDataSource(this._dio);

  final Dio _dio;

  @override
  Future<LotOccupancyDto> fetch(LotId lotId) async {
    final base = '/parking-lots/${lotId.value}';
    final [lotData, summaryData, zonesData] = await Future.wait([
      _get(base),
      _get('$base/occupancy'),
      _get('$base/zones'),
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
    );
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

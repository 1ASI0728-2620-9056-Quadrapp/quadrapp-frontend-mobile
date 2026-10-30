import 'dart:convert';

import 'package:quadrapp_mobile/contexts/occupancy/infrastructure/dto/lot_occupancy_dto.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/storage/key_value_store.dart';

/// Una copia guardada de la ocupación.
class CachedOccupancy {
  const CachedOccupancy({required this.dto, required this.storedAt});

  final LotOccupancyDto dto;

  /// Hora local (UTC) en que se guardó.
  final DateTime storedAt;
}

/// Última ocupación consultada, por estacionamiento (TS13). Se guarda con su
/// marca de tiempo; se borra al cerrar sesión (prefijo `cache.`).
class OccupancyCacheDataSource {
  const OccupancyCacheDataSource(this._store);

  final KeyValueStore _store;

  String _key(LotId lotId) => '${StoreKeys.cache}occupancy.${lotId.value}';

  Future<CachedOccupancy?> read(LotId lotId) async {
    final raw = await _store.getString(_key(lotId));
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return CachedOccupancy(
        dto: LotOccupancyDto.fromJson(json['data'] as Map<String, dynamic>),
        storedAt: DateTime.parse(json['storedAt'] as String),
      );
    } on Object {
      // Una copia corrupta se ignora (y se reemplaza en la próxima consulta).
      return null;
    }
  }

  Future<void> write(
    LotId lotId,
    LotOccupancyDto dto,
    DateTime storedAt,
  ) => _store.setString(
    _key(lotId),
    jsonEncode({
      'storedAt': storedAt.toUtc().toIso8601String(),
      'data': dto.toJson(),
    }),
  );
}

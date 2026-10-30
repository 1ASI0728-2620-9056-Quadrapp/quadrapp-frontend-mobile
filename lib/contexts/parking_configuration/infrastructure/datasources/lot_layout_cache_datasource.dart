import 'dart:convert';

import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/dto/lot_layout_dto.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/storage/key_value_store.dart';

/// Distribución guardada con su versión (TS13). Se borra al cerrar sesión
/// (prefijo `cache.`).
class LotLayoutCacheDataSource {
  const LotLayoutCacheDataSource(this._store);

  final KeyValueStore _store;

  String _key(LotId lotId) => '${StoreKeys.cache}layout.${lotId.value}';

  Future<LotLayoutDto?> read(LotId lotId) async {
    final raw = await _store.getString(_key(lotId));
    if (raw == null) return null;
    try {
      return LotLayoutDto.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      // Una copia corrupta se ignora (y se reemplaza en la próxima consulta).
      return null;
    }
  }

  Future<void> write(LotId lotId, LotLayoutDto dto) =>
      _store.setString(_key(lotId), jsonEncode(dto.toJson()));
}

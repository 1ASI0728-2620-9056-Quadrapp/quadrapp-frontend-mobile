import 'dart:convert';

import 'package:quadrapp_mobile/contexts/parking_configuration/domain/entities/layout_draft.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/repositories/layout_draft_store.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/repositories/layout_publisher.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/datasources/layout_publish_datasource.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/dto/layout_draft_dto.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/mappers/layout_draft_mapper.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/network/failure_mapper.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/storage/key_value_store.dart';

/// Guarda el borrador de cada estacionamiento en el `KeyValueStore` con el
/// prefijo `user.`: se borra al cerrar sesión. Uno ilegible se descarta.
class LayoutDraftStoreImpl implements LayoutDraftStore {
  const LayoutDraftStoreImpl(
    this._store, [
    this._mapper = const LayoutDraftMapper(),
  ]);

  final KeyValueStore _store;
  final LayoutDraftMapper _mapper;

  static String _key(LotId lotId) =>
      '${StoreKeys.user}layoutDraft.${lotId.value}';

  @override
  Future<LayoutDraft?> read(LotId lotId) async {
    final raw = await _store.getString(_key(lotId));
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return _mapper.fromDto(LayoutDraftDto.fromJson(json));
    } on Object {
      await _store.remove(_key(lotId));
      return null;
    }
  }

  @override
  Future<void> save(LayoutDraft draft) => _store.setString(
    _key(draft.lotId),
    jsonEncode(_mapper.toDto(draft).toJson()),
  );

  @override
  Future<void> clear(LotId lotId) => _store.remove(_key(lotId));
}

/// Publica con el origen remoto y convierte cualquier falla en una `Failure`.
class LayoutPublisherImpl implements LayoutPublisher {
  const LayoutPublisherImpl({
    required this._remote,
    this._mapper = const LayoutDraftMapper(),
  });

  final LayoutPublishRemoteDataSource _remote;
  final LayoutDraftMapper _mapper;

  @override
  Future<Result<int>> publish(PublishPlan plan) => guardResult(() async {
    final response = await _remote.publish(
      plan.lotId,
      _mapper.toRequest(plan),
    );
    return response.version;
  });
}

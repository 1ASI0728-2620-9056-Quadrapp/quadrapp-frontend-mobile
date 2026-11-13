// US17
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/entities/layout_draft.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/entities/lot_layout.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/repositories/layout_draft_store.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/repositories/layout_publisher.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/network/failure_mapper.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

/// El borrador guardado de un estacionamiento, o `null` si no hay.
class GetLayoutDraft implements UseCase<LayoutDraft?, LotId> {
  const GetLayoutDraft(this._store);

  final LayoutDraftStore _store;

  @override
  Future<Result<LayoutDraft?>> call(LotId lotId) =>
      guardResult(() => _store.read(lotId));
}

/// Guarda el borrador en el teléfono; uno sin cambios se borra.
class SaveLayoutDraft implements UseCase<void, LayoutDraft> {
  const SaveLayoutDraft(this._store);

  final LayoutDraftStore _store;

  @override
  Future<Result<void>> call(LayoutDraft draft) => guardResult(
    () => draft.isEmpty ? _store.clear(draft.lotId) : _store.save(draft),
  );
}

/// Descarta el borrador de un estacionamiento.
class DiscardLayoutDraft implements UseCase<void, LotId> {
  const DiscardLayoutDraft(this._store);

  final LayoutDraftStore _store;

  @override
  Future<Result<void>> call(LotId lotId) =>
      guardResult(() => _store.clear(lotId));
}

/// Lo que se publica: el borrador y la versión publicada sobre la que se hizo.
typedef PublishLayoutParams = ({LayoutDraft draft, LotLayout? base});

/// Publica el borrador como una nueva versión y, si sale bien, lo borra del
/// teléfono. Un borrador sin cambios no se publica.
class PublishLayout implements UseCase<int, PublishLayoutParams> {
  const PublishLayout({required this._publisher, required this._store});

  final LayoutPublisher _publisher;
  final LayoutDraftStore _store;

  @override
  Future<Result<int>> call(PublishLayoutParams params) async {
    final plan = params.draft.plan(params.base);
    if (plan.isEmpty) return Success(params.draft.baseVersion);
    final published = await _publisher.publish(plan);
    if (published is Success<int>) {
      // Publicado: el borrador ya no hace falta (si no se puede borrar, al
      // abrirlo de nuevo su versión base ya no coincide y se descarta).
      await guardResult(() => _store.clear(params.draft.lotId));
    }
    return published;
  }
}

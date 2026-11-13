import 'package:quadrapp_mobile/contexts/parking_configuration/domain/entities/layout_draft.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

/// El borrador de la distribución de cada estacionamiento, guardado solo en el
/// teléfono hasta publicar (US17). Se borra al cerrar sesión.
abstract interface class LayoutDraftStore {
  /// `null` si no hay borrador de [lotId].
  Future<LayoutDraft?> read(LotId lotId);

  Future<void> save(LayoutDraft draft);

  Future<void> clear(LotId lotId);
}

import 'package:quadrapp_mobile/contexts/parking_configuration/domain/entities/layout_draft.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// Publica los cambios de un borrador como una nueva versión de la
/// distribución (`POST /parking-lots/{lotId}/layout/publish`, US17).
// ignore: one_member_abstracts
abstract interface class LayoutPublisher {
  /// La versión publicada. `ValidationFailure` si otra persona publicó antes
  /// (409) o un nombre o código ya existe; `ForbiddenFailure` si el rol no
  /// puede editar la distribución (solo `ADMIN`).
  Future<Result<int>> publish(PublishPlan plan);
}

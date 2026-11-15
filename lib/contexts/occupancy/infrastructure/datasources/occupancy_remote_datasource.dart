import 'package:quadrapp_mobile/contexts/occupancy/infrastructure/dto/lot_occupancy_dto.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

/// Origen remoto de la ocupación. Lo implementan `OccupancyHttpDataSource` y
/// el mock: mismos errores, mismos formatos, mismas garantías (Liskov).
// ignore: one_member_abstracts
abstract interface class OccupancyRemoteDataSource {
  Future<LotOccupancyDto> fetch(LotId lotId);
}

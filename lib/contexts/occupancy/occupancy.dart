/// API pública del contexto `occupancy`: entidades, value objects y casos de
/// uso. Nada más.
library;

export 'application/usecases/get_level_summary.dart';
export 'application/usecases/get_lot_occupancy.dart';
export 'application/usecases/get_zone_summary.dart';
export 'application/usecases/watch_lot_feed.dart';
export 'application/usecases/watch_lot_occupancy.dart';
export 'domain/entities/level_occupancy.dart';
export 'domain/entities/lot_occupancy.dart';
export 'domain/entities/occupancy_feed.dart';
export 'domain/entities/space_change.dart';
export 'domain/entities/space_state.dart';
export 'domain/entities/zone_occupancy.dart';
export 'domain/value_objects/freshness.dart';
export 'domain/value_objects/space_status.dart';

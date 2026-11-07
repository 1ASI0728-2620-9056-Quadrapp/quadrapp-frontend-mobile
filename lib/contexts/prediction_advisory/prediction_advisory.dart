/// API pública del contexto `prediction_advisory`: entidades, value objects y
/// casos de uso. Nada más.
library;

export 'application/usecases/estimate_arrival_eta.dart';
export 'application/usecases/eta_preferences_usecases.dart';
export 'application/usecases/get_lot_forecasts.dart';
export 'application/usecases/get_next_availability.dart';
export 'application/usecases/location_permission_usecases.dart';
export 'application/usecases/recalculate_arrival_advice.dart';
export 'application/usecases/request_arrival_advice.dart';
export 'domain/entities/arrival_advice.dart';
export 'domain/entities/eta_estimate.dart';
export 'domain/entities/eta_preferences.dart';
export 'domain/entities/forecast.dart';
export 'domain/entities/lot_forecasts.dart';
export 'domain/entities/next_availability.dart';
export 'domain/repositories/location_permission_gateway.dart'
    show LocationPermissionStatus;
export 'domain/value_objects/arrival_category.dart';
export 'domain/value_objects/confidence.dart';
export 'domain/value_objects/eta_minutes.dart';
export 'domain/value_objects/forecast_horizon.dart';
export 'domain/value_objects/forecast_validity.dart';
export 'domain/value_objects/geo_point.dart';
export 'domain/value_objects/saturation.dart';

/// API pública del contexto `analytics`: historial de ocupación, horas pico,
/// precisión del pronóstico y exportación de reportes para la experiencia de
/// Operación (US21, US22, US34, TS11). Nada más.
library;

export 'application/usecases/export_analytics_report.dart';
export 'application/usecases/get_forecast_accuracy.dart';
export 'application/usecases/get_occupancy_history.dart';
export 'application/usecases/get_peak_hours.dart';
export 'domain/entities/analytics_report.dart';
export 'domain/entities/forecast_accuracy.dart';
export 'domain/entities/occupancy_history.dart';
export 'domain/entities/peak_hours.dart';
export 'domain/value_objects/analytics_period.dart';
export 'domain/value_objects/occupancy_granularity.dart';

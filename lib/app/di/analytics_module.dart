import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:quadrapp_mobile/app/config/app_config.dart';
import 'package:quadrapp_mobile/app/di/operations_module.dart';
import 'package:quadrapp_mobile/app/di/registrar.dart';
import 'package:quadrapp_mobile/app/mocks/analytics/mock_analytics_datasource.dart';
import 'package:quadrapp_mobile/app/mocks/mock_world.dart';
import 'package:quadrapp_mobile/composition/analytics/analytics_cubit.dart';
import 'package:quadrapp_mobile/contexts/analytics/application/usecases/export_analytics_report.dart';
import 'package:quadrapp_mobile/contexts/analytics/application/usecases/get_forecast_accuracy.dart';
import 'package:quadrapp_mobile/contexts/analytics/application/usecases/get_occupancy_history.dart';
import 'package:quadrapp_mobile/contexts/analytics/application/usecases/get_peak_hours.dart';
import 'package:quadrapp_mobile/contexts/analytics/domain/repositories/analytics_reader.dart';
import 'package:quadrapp_mobile/contexts/analytics/domain/repositories/report_exporter.dart';
import 'package:quadrapp_mobile/contexts/analytics/infrastructure/datasources/analytics_http_datasource.dart';
import 'package:quadrapp_mobile/contexts/analytics/infrastructure/datasources/analytics_remote_datasource.dart';
import 'package:quadrapp_mobile/contexts/analytics/infrastructure/mappers/analytics_mapper.dart';
import 'package:quadrapp_mobile/contexts/analytics/infrastructure/repositories/analytics_repositories.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/application/usecases/get_lot_forecasts.dart';
import 'package:quadrapp_mobile/core/logging/logger.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';

/// Crea el cubit de Analítica y precisión (`/ops/analytics`): el router lo
/// crea al entrar a la ruta y lo cierra al salir.
typedef CreateAnalyticsCubit = AnalyticsCubit Function();

/// El contexto `analytics` (historial de ocupación, horas pico, precisión del
/// pronóstico y reportes, US21, US22, US34, TS11) y su composición. Solo lo
/// usa un rol de Operación; el servidor responde 403 a un conductor y los
/// mocks también. Va después de `prediction_advisory` (usa sus pronósticos).
void registerAnalyticsModule(GetIt locator, AppConfig config) {
  locator
    ..addLazy<AnalyticsMapper>(() => AnalyticsMapper(locator<Logger>()))
    ..addLazy<AnalyticsRemoteDataSource>(
      () => config.useMocks
          ? MockAnalyticsRemoteDataSource(
              locator<MockWorld>(),
              mockCallerRole(locator),
            )
          : AnalyticsHttpDataSource(locator<Dio>()),
    )
    ..addLazy<AnalyticsReader>(
      () => AnalyticsReaderImpl(remote: locator(), mapper: locator()),
    )
    ..addLazy<ReportExporter>(
      () => ReportExporterImpl(remote: locator(), mapper: locator()),
    )
    ..addLazy<GetOccupancyHistory>(() => GetOccupancyHistory(locator()))
    ..addLazy<GetPeakHours>(() => GetPeakHours(locator()))
    ..addLazy<GetForecastAccuracy>(() => GetForecastAccuracy(locator()))
    ..addLazy<ExportAnalyticsReport>(() => ExportAnalyticsReport(locator()))
    ..addValue<CreateAnalyticsCubit>(
      () => AnalyticsCubit(
        getOccupancyHistory: locator(),
        getPeakHours: locator(),
        getForecastAccuracy: locator(),
        getLotForecasts: locator<GetLotForecasts>(),
        exportReport: locator(),
        clock: locator<Clock>(),
      ),
    );
}

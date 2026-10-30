import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:quadrapp_mobile/app/config/app_config.dart';
import 'package:quadrapp_mobile/app/di/registrar.dart';
import 'package:quadrapp_mobile/app/mocks/mock_controls.dart';
import 'package:quadrapp_mobile/app/mocks/mock_world.dart';
import 'package:quadrapp_mobile/app/mocks/prediction_advisory/mock_location.dart';
import 'package:quadrapp_mobile/app/mocks/prediction_advisory/mock_prediction_datasources.dart';
import 'package:quadrapp_mobile/app/mocks/prediction_advisory/mock_traffic_route_provider.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/repositories/selected_lot_store.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/application/usecases/estimate_arrival_eta.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/application/usecases/eta_preferences_usecases.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/application/usecases/get_lot_forecasts.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/application/usecases/get_next_availability.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/application/usecases/location_permission_usecases.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/application/usecases/recalculate_arrival_advice.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/application/usecases/request_arrival_advice.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/repositories/arrival_advice_requester.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/repositories/eta_preferences_store.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/repositories/forecast_reader.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/repositories/location_permission_gateway.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/repositories/next_availability_reader.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/repositories/position_source.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/repositories/route_provider.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/services/device_route_eta_estimator.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/services/manual_eta_estimator.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/services/throttled_route_provider.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/infrastructure/datasources/prediction_http_datasources.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/infrastructure/datasources/prediction_remote_datasources.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/infrastructure/eta/eta_preferences_store_impl.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/infrastructure/eta/geolocator_location_gateway.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/infrastructure/eta/google_routes_provider.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/infrastructure/eta/local_route_provider.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/infrastructure/mappers/prediction_mapper.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/infrastructure/repositories/prediction_repositories.dart';
import 'package:quadrapp_mobile/core/logging/logger.dart';
import 'package:quadrapp_mobile/core/storage/key_value_store.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';

/// Contexto `prediction_advisory`: pronósticos, próxima liberación, asesoría de
/// llegada y ETA en el dispositivo (US09–US14, US36).
///
/// La posición se lee en memoria y nunca se envía a Quadrapp (TS08 esc. 3).
/// Solo si el conductor activa el tráfico, el origen (redondeado a unos 100 m)
/// va directo al proveedor de mapas. Las preferencias del ETA (`user.eta.*`)
/// se borran al cerrar sesión con el resto del prefijo `user.`.
void registerPredictionAdvisoryModule(GetIt locator, AppConfig config) {
  locator
    // --- infraestructura ---
    ..addLazy<ForecastRemoteDataSource>(
      () => config.useMocks
          ? MockForecastRemoteDataSource(locator<MockWorld>())
          : ForecastHttpDataSource(locator<Dio>()),
    )
    ..addLazy<ArrivalAdviceRemoteDataSource>(
      () => config.useMocks
          ? MockArrivalAdviceRemoteDataSource(locator<MockWorld>())
          : ArrivalAdviceHttpDataSource(locator<Dio>()),
    )
    ..addLazy<NextAvailabilityRemoteDataSource>(
      () => config.useMocks
          ? MockNextAvailabilityRemoteDataSource(locator<MockWorld>())
          : NextAvailabilityHttpDataSource(locator<Dio>()),
    )
    ..addLazy<PredictionMapper>(() => PredictionMapper(locator<Logger>()))
    ..addLazy<ForecastReader>(
      () => ForecastReaderImpl(
        remote: locator(),
        mapper: locator(),
        clock: locator<Clock>(),
      ),
    )
    ..addLazy<ArrivalAdviceRequester>(
      () => ArrivalAdviceRequesterImpl(
        remote: locator(),
        mapper: locator(),
        clock: locator<Clock>(),
      ),
    )
    ..addLazy<NextAvailabilityReader>(
      () => NextAvailabilityReaderImpl(remote: locator(), mapper: locator()),
    )
    // --- ETA en el dispositivo ---
    // Con mocks, el permiso y la posición son simulados (`/debug/mocks`).
    ..addLazy<PositionSource>(
      () => config.useMocks
          ? MockLocationGateway(
              locator<MockControls>(),
              clock: locator<Clock>(),
              world: locator<MockWorld>(),
              selectedLot: locator<SelectedLotStore>(),
            )
          : const GeolocatorLocationGateway(),
    )
    ..addLazy<LocationPermissionGateway>(
      () => config.useMocks
          ? MockLocationGateway(locator<MockControls>())
          : const GeolocatorLocationGateway(),
    )
    // La estimación local (sin red). El proveedor de mapas con tráfico es
    // opcional y solo lo usa el estimador si el conductor lo activó; cambiar de
    // proveedor es cambiar `_trafficProvider` (docs/04).
    ..addLazy<RouteProvider>(LocalRouteProvider.new)
    ..addLazy<ManualEtaEstimator>(ManualEtaEstimator.new)
    ..addLazy<DeviceRouteEtaEstimator>(
      () => DeviceRouteEtaEstimator(
        positionSource: locator(),
        routeProvider: locator(),
        trafficProvider: _trafficProvider(locator, config),
      ),
    )
    ..addLazy<EtaPreferencesStore>(
      () => EtaPreferencesStoreImpl(locator<KeyValueStore>()),
    )
    ..addLazy<GetEtaPreferences>(() => GetEtaPreferences(locator()))
    ..addLazy<SaveEtaPreferences>(() => SaveEtaPreferences(locator()))
    // --- casos de uso ---
    ..addLazy<GetLotForecasts>(() => GetLotForecasts(locator()))
    ..addLazy<GetNextAvailability>(() => GetNextAvailability(locator()))
    ..addLazy<RequestArrivalAdvice>(() => RequestArrivalAdvice(locator()))
    ..addLazy<RecalculateArrivalAdvice>(
      () => RecalculateArrivalAdvice(locator()),
    )
    ..addLazy<EstimateArrivalEta>(
      () => EstimateArrivalEta(
        manual: locator<ManualEtaEstimator>(),
        automatic: locator<DeviceRouteEtaEstimator>(),
      ),
    )
    ..addLazy<GetLocationPermissionStatus>(
      () => GetLocationPermissionStatus(locator()),
    )
    ..addLazy<RequestLocationPermission>(
      () => RequestLocationPermission(locator()),
    );
}

/// El proveedor de mapas con tráfico: el simulado con mocks; Google Routes si
/// hay clave (`ROUTES_API_KEY`), con las consultas limitadas por
/// `ThrottledRouteProvider`; y ninguno sin clave (la app usa la estimación
/// local).
RouteProvider? _trafficProvider(GetIt locator, AppConfig config) {
  if (config.useMocks) {
    return MockTrafficRouteProvider(locator<MockControls>());
  }
  if (config.routesApiKey.isEmpty) return null;
  return ThrottledRouteProvider(
    GoogleRoutesProvider(
      dio: GoogleRoutesProvider.newClient(),
      apiKey: config.routesApiKey,
    ),
    locator<Clock>(),
  );
}

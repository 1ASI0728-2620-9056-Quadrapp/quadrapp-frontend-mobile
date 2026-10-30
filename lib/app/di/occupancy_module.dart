import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:quadrapp_mobile/app/config/app_config.dart';
import 'package:quadrapp_mobile/app/di/registrar.dart';
import 'package:quadrapp_mobile/app/mocks/mock_world.dart';
import 'package:quadrapp_mobile/app/mocks/occupancy/mock_occupancy_datasources.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/repositories/access_token_holder.dart';
import 'package:quadrapp_mobile/contexts/occupancy/application/usecases/get_level_summary.dart';
import 'package:quadrapp_mobile/contexts/occupancy/application/usecases/get_lot_occupancy.dart';
import 'package:quadrapp_mobile/contexts/occupancy/application/usecases/get_zone_summary.dart';
import 'package:quadrapp_mobile/contexts/occupancy/application/usecases/watch_lot_feed.dart';
import 'package:quadrapp_mobile/contexts/occupancy/application/usecases/watch_lot_occupancy.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/repositories/occupancy_reader.dart';
import 'package:quadrapp_mobile/contexts/occupancy/domain/repositories/occupancy_realtime.dart';
import 'package:quadrapp_mobile/contexts/occupancy/infrastructure/datasources/occupancy_cache_datasource.dart';
import 'package:quadrapp_mobile/contexts/occupancy/infrastructure/datasources/occupancy_http_datasource.dart';
import 'package:quadrapp_mobile/contexts/occupancy/infrastructure/datasources/occupancy_realtime_datasource.dart';
import 'package:quadrapp_mobile/contexts/occupancy/infrastructure/datasources/occupancy_remote_datasource.dart';
import 'package:quadrapp_mobile/contexts/occupancy/infrastructure/datasources/occupancy_ws_datasource.dart';
import 'package:quadrapp_mobile/contexts/occupancy/infrastructure/mappers/occupancy_mapper.dart';
import 'package:quadrapp_mobile/contexts/occupancy/infrastructure/repositories/occupancy_reader_impl.dart';
import 'package:quadrapp_mobile/contexts/occupancy/infrastructure/repositories/occupancy_realtime_impl.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/logging/logger.dart';
import 'package:quadrapp_mobile/core/network/web_socket_connector.dart';
import 'package:quadrapp_mobile/core/storage/key_value_store.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';

/// Contexto `occupancy`: ocupación actual y en tiempo real (US05–US08, TS09,
/// TS13).
///
/// La caché de la última ocupación (`cache.`) se limpia al cerrar sesión por su
/// prefijo (`KeyValueResettable` en `sign_out_module`).
void registerOccupancyModule(GetIt locator, AppConfig config) {
  locator
    // --- infraestructura ---
    ..addLazy<OccupancyRemoteDataSource>(
      () => config.useMocks
          ? MockOccupancyRemoteDataSource(locator<MockWorld>())
          : OccupancyHttpDataSource(locator<Dio>()),
    )
    ..addLazy<OccupancyRealtimeDataSource>(
      () => config.useMocks
          ? MockOccupancyRealtimeDataSource(locator<MockWorld>())
          : OccupancyWsDataSource(
              connector: locator<WebSocketConnector>(),
              urlFor: (lotId) => occupancySocketUri(config.apiBaseUrl, lotId),
              // Se lee en cada conexión: el token cambia con cada refresh.
              accessToken: () => locator<AccessTokenHolder>().current?.value,
              logger: locator<Logger>(),
            ),
    )
    ..addLazy<OccupancyCacheDataSource>(
      () => OccupancyCacheDataSource(locator<KeyValueStore>()),
    )
    ..addLazy<OccupancyMapper>(() => OccupancyMapper(locator<Logger>()))
    ..addLazy<OccupancyReader>(
      () => OccupancyReaderImpl(
        remote: locator(),
        cache: locator(),
        mapper: locator(),
        clock: locator<Clock>(),
      ),
    )
    ..addLazy<OccupancyRealtime>(
      () => OccupancyRealtimeImpl(
        dataSource: locator(),
        reader: locator(),
        mapper: locator(),
        clock: locator<Clock>(),
      ),
    )
    // --- casos de uso ---
    ..addLazy<GetLotOccupancy>(() => GetLotOccupancy(locator()))
    ..addLazy<WatchLotOccupancy>(() => WatchLotOccupancy(locator()))
    ..addLazy<WatchLotFeed>(() => WatchLotFeed(locator()))
    ..addLazy<GetZoneSummary>(GetZoneSummary.new)
    ..addLazy<GetLevelSummary>(GetLevelSummary.new);
}

/// `ws://` o `wss://` según la URL base de la API, más `/ws/parking-lots/{id}`
/// (docs/07). La autenticación va por cabecera, no en la URL.
Uri occupancySocketUri(String apiBaseUrl, LotId lotId) {
  final base = Uri.parse(apiBaseUrl);
  return Uri(
    scheme: base.scheme == 'https' ? 'wss' : 'ws',
    host: base.host,
    port: base.hasPort ? base.port : null,
    path:
        '${base.path.replaceAll(RegExp(r'/+$'), '')}'
        '/ws/parking-lots/${lotId.value}',
  );
}

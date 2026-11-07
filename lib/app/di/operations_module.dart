import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:quadrapp_mobile/app/config/app_config.dart';
import 'package:quadrapp_mobile/app/di/registrar.dart';
import 'package:quadrapp_mobile/app/mocks/mock_world.dart';
import 'package:quadrapp_mobile/app/mocks/parking_sensing/mock_device_datasources.dart';
import 'package:quadrapp_mobile/app/mocks/shift/mock_shift_datasource.dart';
import 'package:quadrapp_mobile/composition/shift/get_shift_overview.dart';
import 'package:quadrapp_mobile/composition/shift/shift_overview_mapper.dart';
import 'package:quadrapp_mobile/composition/shift/shift_overview_reader_impl.dart';
import 'package:quadrapp_mobile/composition/shift/shift_overview_remote_datasource.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/repositories/access_token_holder.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/user_role.dart';
import 'package:quadrapp_mobile/contexts/iam/presentation/cubit/auth_cubit.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/application/usecases/decommission_device.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/application/usecases/get_device_inventory.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/application/usecases/register_device.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/domain/repositories/device_reader.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/domain/repositories/device_registry.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/infrastructure/datasources/device_http_datasource.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/infrastructure/datasources/device_remote_datasource.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/infrastructure/mappers/device_mapper.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/infrastructure/repositories/device_reader_impl.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/infrastructure/repositories/device_registry_impl.dart';
import 'package:quadrapp_mobile/core/logging/logger.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';

/// Experiencia de Operación: el contexto `parking_sensing` (inventario y salud
/// de dispositivos, US20, US32, TS10) y la composición `shift` (consola de
/// turno, US29, TS17). Solo las usa un rol de Operación; el servidor responde
/// 403 a un conductor y los mocks también.
void registerOperationsModule(GetIt locator, AppConfig config) {
  locator
    // --- parking_sensing: infraestructura ---
    ..addLazy<DeviceMapper>(() => DeviceMapper(locator<Logger>()))
    ..addLazy<DeviceRemoteDataSource>(
      () => config.useMocks
          ? MockDeviceRemoteDataSource(
              locator<MockWorld>(),
              _callerRole(locator),
            )
          : DeviceHttpDataSource(locator<Dio>()),
    )
    ..addLazy<DeviceReader>(
      () => DeviceReaderImpl(
        remote: locator(),
        mapper: locator(),
        clock: locator<Clock>(),
      ),
    )
    ..addLazy<DeviceRegistry>(
      () => DeviceRegistryImpl(remote: locator(), mapper: locator()),
    )
    // --- parking_sensing: casos de uso ---
    ..addLazy<GetDeviceInventory>(() => GetDeviceInventory(locator()))
    ..addLazy<RegisterDevice>(() => RegisterDevice(locator()))
    ..addLazy<DecommissionDevice>(() => DecommissionDevice(locator()))
    // --- shift ---
    ..addLazy<ShiftOverviewMapper>(
      () => ShiftOverviewMapper(locator<Logger>()),
    )
    ..addLazy<ShiftOverviewRemoteDataSource>(
      () => config.useMocks
          ? MockShiftOverviewRemoteDataSource(
              locator<MockWorld>(),
              _callerRole(locator),
            )
          : ShiftOverviewHttpDataSource(locator<Dio>()),
    )
    ..addLazy<ShiftOverviewReader>(
      () => ShiftOverviewReaderImpl(
        remote: locator(),
        mapper: locator(),
        clock: locator<Clock>(),
      ),
    )
    ..addLazy<GetShiftOverview>(() => GetShiftOverview(locator()));
}

/// El rol de quien llama, para los mocks de consola (no pasan por el
/// interceptor de red, así que el token real lo valida el servidor): el rol con
/// el que se emitió el token de acceso vigente o, si no hay token (una sesión
/// restaurada), el rol de la sesión.
String? Function() _callerRole(GetIt locator) => () {
  final token = locator<AccessTokenHolder>().current?.value;
  final world = locator<MockWorld>();
  final fromToken = world.iam.roleForAccessToken(token);
  if (fromToken != null) return fromToken;
  final auth = locator<AuthCubit>().state;
  if (auth is! Authenticated) return null;
  return switch (auth.session.role) {
    UserRole.driver => 'DRIVER',
    UserRole.operator => 'OPERATOR',
    UserRole.admin => 'ADMIN',
  };
};

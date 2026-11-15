import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:quadrapp_mobile/app/config/app_config.dart';
import 'package:quadrapp_mobile/app/di/operations_module.dart';
import 'package:quadrapp_mobile/app/di/registrar.dart';
import 'package:quadrapp_mobile/app/mocks/mock_world.dart';
import 'package:quadrapp_mobile/app/mocks/tenant/mock_tenant_datasources.dart';
import 'package:quadrapp_mobile/composition/devices/devices_cubit.dart';
import 'package:quadrapp_mobile/composition/more/more_cubit.dart';
import 'package:quadrapp_mobile/contexts/iam/application/usecases/tenant_admin_usecases.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/repositories/tenant_directory.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/datasources/tenant_remote_datasource.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/mappers/tenant_mapper.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/repositories/tenant_repositories.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/application/usecases/calendar_usecases.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/repositories/campus_calendar.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/datasources/calendar_datasource.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/mappers/calendar_mapper.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/repositories/campus_calendar_impl.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/application/usecases/get_device_inventory.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/application/usecases/report_device_problem.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/domain/repositories/problem_reporter.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/infrastructure/datasources/problem_report_datasource.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/infrastructure/repositories/problem_reporter_impl.dart';
import 'package:quadrapp_mobile/core/logging/logger.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';

/// Crea el cubit de Más (`/ops/more`).
typedef CreateMoreCubit = MoreCubit Function();

/// Crea el cubit de Dispositivos (`/ops/more/devices`).
typedef CreateDevicesCubit = DevicesCubit Function();

/// La administración de la universidad (experiencia de Operación): dominios y
/// equipo (`iam`, US30, US31), calendario del campus
/// (`parking_configuration`, US35) y reportes de problemas
/// (`parking_sensing`, US20), con sus composiciones `more` y `devices`. Va
/// después de `registerOperationsModule` (usa `GetDeviceInventory`).
void registerAdministrationModule(GetIt locator, AppConfig config) {
  final callerRole = mockCallerRole(locator);
  locator
    // --- iam: dominios y equipo ---
    ..addLazy<TenantMapper>(() => TenantMapper(locator<Logger>()))
    ..addLazy<TenantRemoteDataSource>(
      () => config.useMocks
          ? MockTenantRemoteDataSource(locator<MockWorld>(), callerRole)
          : TenantHttpDataSource(locator<Dio>()),
    )
    ..addLazy<DomainRegistry>(
      () => DomainRegistryImpl(remote: locator(), mapper: locator()),
    )
    ..addLazy<TeamDirectory>(
      () => TeamDirectoryImpl(remote: locator(), mapper: locator()),
    )
    ..addLazy<GetInstitutionDomains>(() => GetInstitutionDomains(locator()))
    ..addLazy<AddInstitutionDomain>(() => AddInstitutionDomain(locator()))
    ..addLazy<RemoveInstitutionDomain>(
      () => RemoveInstitutionDomain(locator()),
    )
    ..addLazy<GetTeam>(() => GetTeam(locator()))
    ..addLazy<InviteTeamMember>(() => InviteTeamMember(locator()))
    // --- parking_configuration: calendario del campus ---
    ..addLazy<CalendarMapper>(() => CalendarMapper(locator<Logger>()))
    ..addLazy<CalendarRemoteDataSource>(
      () => config.useMocks
          ? MockCalendarRemoteDataSource(locator<MockWorld>(), callerRole)
          : CalendarHttpDataSource(locator<Dio>()),
    )
    ..addLazy<CampusCalendar>(
      () => CampusCalendarImpl(remote: locator(), mapper: locator()),
    )
    ..addLazy<GetCampusCalendar>(() => GetCampusCalendar(locator()))
    ..addLazy<CreateCalendarEvent>(() => CreateCalendarEvent(locator()))
    ..addLazy<CancelCalendarEvent>(() => CancelCalendarEvent(locator()))
    // --- parking_sensing: reportes de problemas ---
    ..addLazy<ProblemReportRemoteDataSource>(
      () => config.useMocks
          ? MockProblemReportRemoteDataSource(locator<MockWorld>(), callerRole)
          : ProblemReportHttpDataSource(locator<Dio>()),
    )
    ..addLazy<ProblemReporter>(() => ProblemReporterImpl(locator()))
    ..addLazy<ReportDeviceProblem>(() => ReportDeviceProblem(locator()))
    // --- composiciones ---
    ..addValue<CreateMoreCubit>(
      () => MoreCubit(
        getCampusCalendar: locator(),
        createCalendarEvent: locator(),
        cancelCalendarEvent: locator(),
        getInstitutionDomains: locator(),
        addInstitutionDomain: locator(),
        removeInstitutionDomain: locator(),
        getTeam: locator(),
        inviteTeamMember: locator(),
        clock: locator<Clock>(),
      ),
    )
    ..addValue<CreateDevicesCubit>(
      () => DevicesCubit(
        getDeviceInventory: locator<GetDeviceInventory>(),
        reportDeviceProblem: locator(),
      ),
    );
}

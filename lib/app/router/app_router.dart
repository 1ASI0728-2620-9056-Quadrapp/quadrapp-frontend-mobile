// US01, US02, US03, US04

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:quadrapp_mobile/app/di/alerts_module.dart';
import 'package:quadrapp_mobile/app/di/arrival_module.dart';
import 'package:quadrapp_mobile/app/di/auth_module.dart';
import 'package:quadrapp_mobile/app/di/eta_module.dart';
import 'package:quadrapp_mobile/app/di/forecast_module.dart';
import 'package:quadrapp_mobile/app/di/operations_module.dart';
import 'package:quadrapp_mobile/app/di/parking_configuration_module.dart';
import 'package:quadrapp_mobile/app/di/sede_module.dart';
import 'package:quadrapp_mobile/app/di/zones_module.dart';
import 'package:quadrapp_mobile/app/gallery/gallery_page.dart';
import 'package:quadrapp_mobile/app/router/auth_refresh_listenable.dart';
import 'package:quadrapp_mobile/app/router/fade_through_page.dart';
import 'package:quadrapp_mobile/app/session/session_expiry_coordinator.dart';
import 'package:quadrapp_mobile/app/shell/app_shell.dart';
import 'package:quadrapp_mobile/app/shell/driver_scope.dart';
import 'package:quadrapp_mobile/app/shell/operations_scope.dart';
import 'package:quadrapp_mobile/app/shell/operations_soon_page.dart';
import 'package:quadrapp_mobile/app/shell/shell_tabs.dart';
import 'package:quadrapp_mobile/composition/alerts/alerts_tab_page.dart';
import 'package:quadrapp_mobile/composition/arrival/home_page.dart';
import 'package:quadrapp_mobile/composition/forecast/forecast_tab_page.dart';
import 'package:quadrapp_mobile/composition/language/language_cubit.dart';
import 'package:quadrapp_mobile/composition/layout_editor/layout_editor_page.dart';
import 'package:quadrapp_mobile/composition/lots/lots_page.dart';
import 'package:quadrapp_mobile/composition/settings/settings_page.dart';
import 'package:quadrapp_mobile/composition/shift/shift_page.dart';
import 'package:quadrapp_mobile/composition/zones/level_page.dart';
import 'package:quadrapp_mobile/composition/zones/zone_page.dart';
import 'package:quadrapp_mobile/composition/zones/zones_tab_page.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/entities/otp_challenge.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/user_role.dart';
import 'package:quadrapp_mobile/contexts/iam/presentation/cubit/auth_cubit.dart';
import 'package:quadrapp_mobile/contexts/iam/presentation/pages/legal_page.dart';
import 'package:quadrapp_mobile/contexts/iam/presentation/pages/login_page.dart';
import 'package:quadrapp_mobile/contexts/iam/presentation/pages/session_splash_page.dart';
import 'package:quadrapp_mobile/contexts/iam/presentation/pages/verify_code_page.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';

/// Rutas de la app.
const String splashPath = '/';
const String loginPath = '/login';
const String verifyPath = '/login/verify';
const String legalPath = '/legal';
const String homePath = '/home';
const String zonesPath = '/zones';

/// Un pabellón de la sede elegida (`/zones/:zoneId`).
String zonePath(ZoneId zoneId) => '$zonesPath/${zoneId.value}';

/// Un nivel de un pabellón (`/zones/:zoneId/levels/:levelId`).
String levelPath(ZoneId zoneId, LevelId levelId) =>
    '$zonesPath/${zoneId.value}/levels/${levelId.value}';
const String forecastPath = '/forecast';
const String alertsPath = '/alerts';
const String accountPath = '/account';

/// Rutas de la experiencia de Operación (`ADMIN` y `OPERATOR`).
const String opsPath = '/ops';
const String opsShiftPath = '/ops/shift';
const String opsZonesPath = '/ops/zones';

/// Una zona del estacionamiento elegido, en Operación (`/ops/zones/:zoneId`).
String opsZonePath(ZoneId zoneId) => '$opsZonesPath/${zoneId.value}';

/// Un nivel de una zona, en Operación
/// (`/ops/zones/:zoneId/levels/:levelId`).
String opsLevelPath(ZoneId zoneId, LevelId levelId) =>
    '$opsZonesPath/${zoneId.value}/levels/${levelId.value}';

/// «Editar distribución» del estacionamiento elegido (solo `ADMIN`).
const String opsLayoutPath = '/ops/zones/layout';
const String opsAccessesPath = '/ops/accesses';
const String opsAnalyticsPath = '/ops/analytics';
const String opsMorePath = '/ops/more';

/// Dispositivos cuelga de Más (como el diseño), sin barra propia.
const String opsDevicesPath = '/ops/more/devices';

/// La cuenta de Operación: se abre desde el avatar, sin barra inferior.
const String opsAccountPath = '/ops/account';
const String debugMocksPath = '/debug/mocks';

/// Motivo con el que `/login` avisa que la sesión venció (US03).
const String expiredReason = 'expired';

/// El inicio de la experiencia que corresponde a [role]: Conductor (`/home`) o
/// Operación (`/ops/shift`).
String homePathFor(UserRole role) =>
    role.isOperations ? opsShiftPath : homePath;

/// ¿Es [location] una ruta de la experiencia de Operación?
bool isOperationsLocation(String location) =>
    location == opsPath || location.startsWith('$opsPath/');

/// ¿Es [location] una ruta de la experiencia de Conductor?
bool isDriverLocation(String location) =>
    location == homePath ||
    location == zonesPath ||
    location.startsWith('$zonesPath/') ||
    location == forecastPath ||
    location == alertsPath ||
    location == accountPath;

/// Rutas de la app (docs/02). El `redirect` decide por el estado de sesión:
///
/// - mientras se lee la sesión guardada: `/` (skeleton);
/// - con sesión: el inicio de su experiencia, `/home` (Conductor) o
///   `/ops/shift` (Operación), nunca `/` ni `/login`; y un rol no llega a las
///   rutas del otro (se le lleva a su inicio). **Esto es solo experiencia de
///   usuario:** la protección real es el 403 del servidor (docs/04);
/// - sin sesión: `/login`, o `/login?reason=expired` si
///   `SessionExpiryCoordinator.hasExpired` (US03), esté donde esté la
///   persona. Solo las rutas de depuración se pueden abrir sin sesión.
///
/// Se vuelve a evaluar cuando cambia el `AuthCubit` o el coordinador
/// (`refreshListenable`). Las dependencias llegan por parámetro (no usa
/// `get_it`), así se prueba sin la raíz de composición.
///
/// La galería y el panel de depuración solo se registran en debug (o si se
/// fuerzan, para las pruebas); en release no existen. El panel además necesita
/// [debugPanelBuilder] (solo existe con mocks).
GoRouter createAppRouter({
  required AuthCubit authCubit,
  required SessionExpiryCoordinator expiry,
  required CreateLoginCubit createLoginCubit,
  required CreateVerifyCodeCubit createVerifyCodeCubit,
  required CreateSignOutCubit createSignOutCubit,
  required CreateArrivalCubit createArrivalCubit,
  required CreateSedeCubit createSedeCubit,
  required CreateEtaCubit createEtaCubit,
  required CreateZonesCubit createZonesCubit,
  required CreateForecastCubit createForecastCubit,
  required CreateAlertsCubit createAlertsCubit,
  required CreateShiftCubit createShiftCubit,
  required CreateLayoutEditorCubit createLayoutEditorCubit,
  required Clock clock,
  LanguageCubit? languageCubit,
  CreateArrivalMapCubit? createArrivalMapCubit,
  bool enableGallery = kDebugMode,
  bool enableDebugPanel = kDebugMode,
  WidgetBuilder? debugPanelBuilder,
}) {
  final showDebugPanel = enableDebugPanel && debugPanelBuilder != null;
  bool isDebugRoute(String location) =>
      (enableGallery && location == galleryPath) ||
      (showDebugPanel && location == debugMocksPath);

  return GoRouter(
    initialLocation: splashPath,
    refreshListenable: Listenable.merge([
      expiry,
      AuthRefreshListenable(authCubit),
    ]),
    redirect: (context, state) {
      final location = state.matchedLocation;
      final auth = authCubit.state;
      if (auth is AuthUnknown) {
        return location == splashPath ? null : splashPath;
      }
      if (auth is Authenticated) {
        final role = auth.session.role;
        final home = homePathFor(role);
        if (location == splashPath || location.startsWith(loginPath)) {
          return home;
        }
        // Cada rol, solo en su experiencia (el servidor responde 403 igual).
        if (role.isOperations && isDriverLocation(location)) return home;
        if (!role.isOperations && isOperationsLocation(location)) return home;
        return null;
      }
      if (location.startsWith(loginPath) || location == legalPath) return null;
      // La expiración tiene prioridad, incluso sobre las rutas de depuración.
      if (expiry.hasExpired) return '$loginPath?reason=$expiredReason';
      return isDebugRoute(location) ? null : loginPath;
    },
    routes: [
      GoRoute(
        path: splashPath,
        builder: (context, state) => const SessionSplashPage(),
      ),
      GoRoute(
        path: loginPath,
        pageBuilder: (context, state) => fadeThroughPage(
          key: state.pageKey,
          child: BlocProvider(
            create: (_) => createLoginCubit(
              (challenge) => context.push(verifyPath, extra: challenge),
            ),
            child: LoginPage(
              sessionExpired:
                  state.uri.queryParameters['reason'] == expiredReason,
              onNoticeShown: expiry.acknowledge,
              onOpenLegal: () => context.push(legalPath),
            ),
          ),
        ),
        routes: [
          GoRoute(
            path: 'verify',
            // Sin un código pedido no hay nada que verificar (por ejemplo,
            // tras reiniciar la app en esta pantalla).
            redirect: (context, state) =>
                state.extra is OtpChallenge ? null : loginPath,
            pageBuilder: (context, state) {
              final challenge = state.extra! as OtpChallenge;
              return fadeThroughPage(
                key: state.pageKey,
                child: BlocProvider(
                  create: (_) => createVerifyCodeCubit(challenge, (session) {
                    expiry.acknowledge();
                    authCubit.sessionStarted(session);
                  }),
                  child: VerifyCodePage(
                    validity: challenge.expiresIn,
                    onChangeEmail: () => context.canPop()
                        ? context.pop()
                        : context.go(loginPath),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      // Las cuatro pestañas del Conductor (docs/02): cada rama conserva su
      // estado. La sede elegida es una sola para todas (el cubit vive aquí).
      StatefulShellRoute(
        builder: (context, state, navigationShell) => DriverScope(
          createSedeCubit: createSedeCubit,
          createEtaCubit: createEtaCubit,
          createZonesCubit: createZonesCubit,
          child: navigationShell,
        ),
        navigatorContainerBuilder: (context, navigationShell, children) =>
            AppShell(
              navigationShell: navigationShell,
              tabs: AppTab.driver,
              children: children,
            ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: homePath,
                builder: (context, state) {
                  final auth = authCubit.state;
                  final page = HomePage(
                    clock: clock,
                    tabIndex: AppTab.home,
                    showMap: createArrivalMapCubit != null,
                    fullName: auth is Authenticated
                        ? auth.session.fullName
                        : null,
                    onOpenAccount: () => context.push(accountPath),
                    onOpenForecast: () => context.go(forecastPath),
                  );
                  return MultiBlocProvider(
                    providers: [
                      BlocProvider(create: (_) => createArrivalCubit()),
                      if (createArrivalMapCubit != null)
                        BlocProvider(create: (_) => createArrivalMapCubit()),
                    ],
                    child: page,
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: zonesPath,
                builder: (context, state) => ZonesTabPage(
                  clock: clock,
                  tabIndex: AppTab.zones,
                  onOpenZone: (zoneId) => context.push(zonePath(zoneId)),
                  onOpenLevel: (zoneId, levelId) =>
                      context.push(levelPath(zoneId, levelId)),
                ),
                // El pabellón y el nivel son hermanos: un pabellón con un solo
                // nivel salta directo al nivel y «atrás» vuelve a Zonas.
                routes: [
                  GoRoute(
                    path: ':zoneId',
                    builder: (context, state) => ZonePage(
                      zoneId: ZoneId(_idOf(state, 'zoneId')),
                      clock: clock,
                      onBack: () => _back(context),
                      onOpenLevel: (zoneId, levelId) =>
                          context.push(levelPath(zoneId, levelId)),
                    ),
                  ),
                  GoRoute(
                    path: ':zoneId/levels/:levelId',
                    builder: (context, state) => LevelPage(
                      zoneId: ZoneId(_idOf(state, 'zoneId')),
                      levelId: LevelId(_idOf(state, 'levelId')),
                      clock: clock,
                      onBack: () => _back(context),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: forecastPath,
                builder: (context, state) => BlocProvider(
                  create: (_) => createForecastCubit(),
                  child: ForecastTabPage(
                    clock: clock,
                    tabIndex: AppTab.forecast,
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: alertsPath,
                builder: (context, state) => BlocProvider(
                  create: (_) => createAlertsCubit(),
                  child: const AlertsTabPage(tabIndex: AppTab.alerts),
                ),
              ),
            ],
          ),
        ],
      ),
      // El resumen de términos y privacidad: se abre desde el acceso y desde la
      // cuenta, con o sin sesión.
      GoRoute(
        path: legalPath,
        builder: (context, state) => LegalPage(
          onBack: () =>
              context.canPop() ? context.pop() : context.go(loginPath),
        ),
      ),
      // La cuenta del Conductor: se llega desde el perfil de Inicio, sin barra
      // inferior y con la flecha de volver.
      GoRoute(
        path: accountPath,
        builder: (context, state) {
          final auth = authCubit.state;
          // El redirect nunca deja entrar sin sesión.
          if (auth is! Authenticated) return const SizedBox.shrink();
          return BlocProvider(
            create: (_) => createSignOutCubit(authCubit.sessionEnded),
            child: SettingsPage(
              session: auth.session,
              languageCubit: languageCubit,
              onBack: () =>
                  context.canPop() ? context.pop() : context.go(homePath),
              onOpenLegal: () => context.push(legalPath),
            ),
          );
        },
      ),
      // La cuenta de Operación: se llega desde el avatar, sin barra inferior y
      // con la flecha de volver.
      GoRoute(
        path: opsAccountPath,
        builder: (context, state) {
          final auth = authCubit.state;
          // El redirect nunca deja entrar sin sesión.
          if (auth is! Authenticated) return const SizedBox.shrink();
          return BlocProvider(
            create: (_) => createSignOutCubit(authCubit.sessionEnded),
            child: SettingsPage(
              session: auth.session,
              languageCubit: languageCubit,
              onBack: () =>
                  context.canPop() ? context.pop() : context.go(opsShiftPath),
              onOpenLegal: () => context.push(legalPath),
            ),
          );
        },
      ),
      // La experiencia de Operación (administrador de universidad: ADMIN y
      // OPERATOR, la misma barra): su propio shell. El estacionamiento elegido
      // y sus zonas en vivo son unos solos para todas las pestañas.
      StatefulShellRoute(
        builder: (context, state, navigationShell) => OperationsScope(
          createSedeCubit: createSedeCubit,
          createZonesCubit: createZonesCubit,
          child: navigationShell,
        ),
        navigatorContainerBuilder: (context, navigationShell, children) =>
            AppShell(
              navigationShell: navigationShell,
              tabs: OpsTab.operations,
              children: children,
            ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: opsShiftPath,
                builder: (context, state) => BlocProvider(
                  create: (_) => createShiftCubit(),
                  child: ShiftPage(
                    clock: clock,
                    tabIndex: OpsTab.home,
                    onOpenDevices: () => context.go(opsDevicesPath),
                    onOpenAccount: () => context.push(opsAccountPath),
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: opsZonesPath,
                builder: (context, state) => LotsPage(
                  clock: clock,
                  tabIndex: OpsTab.zones,
                  onOpenZone: (zoneId) => context.push(opsZonePath(zoneId)),
                  onOpenLevel: (zoneId, levelId) =>
                      context.push(opsLevelPath(zoneId, levelId)),
                  onOpenAccount: () => context.push(opsAccountPath),
                  onManageLayout: _isAdmin(authCubit)
                      ? () => context.push(opsLayoutPath)
                      : null,
                ),
                // La zona y el nivel son los mismos del Conductor.
                routes: [
                  // Antes que `:zoneId`, que también calzaría con «layout».
                  // Solo el administrador edita la distribución; al operador
                  // se le devuelve a Estacionamientos (el servidor responde
                  // 403 igual).
                  GoRoute(
                    path: 'layout',
                    redirect: (context, state) =>
                        _isAdmin(authCubit) ? null : opsZonesPath,
                    builder: (context, state) => BlocProvider(
                      create: (_) => createLayoutEditorCubit(),
                      child: LayoutEditorPage(
                        onBack: () => _backTo(context, opsZonesPath),
                      ),
                    ),
                  ),
                  GoRoute(
                    path: ':zoneId',
                    builder: (context, state) => ZonePage(
                      zoneId: ZoneId(_idOf(state, 'zoneId')),
                      clock: clock,
                      onBack: () => _backTo(context, opsZonesPath),
                      onOpenLevel: (zoneId, levelId) =>
                          context.push(opsLevelPath(zoneId, levelId)),
                    ),
                  ),
                  GoRoute(
                    path: ':zoneId/levels/:levelId',
                    builder: (context, state) => LevelPage(
                      zoneId: ZoneId(_idOf(state, 'zoneId')),
                      levelId: LevelId(_idOf(state, 'levelId')),
                      clock: clock,
                      onBack: () => _backTo(context, opsZonesPath),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: opsAccessesPath,
                builder: (context, state) => OperationsSoonPage(
                  kind: OpsSoon.accesses,
                  tabIndex: OpsTab.accesses,
                  onOpenAccount: () => context.push(opsAccountPath),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: opsAnalyticsPath,
                builder: (context, state) => OperationsSoonPage(
                  kind: OpsSoon.analytics,
                  tabIndex: OpsTab.analytics,
                  onOpenAccount: () => context.push(opsAccountPath),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: opsMorePath,
                builder: (context, state) => OperationsSoonPage(
                  kind: OpsSoon.more,
                  tabIndex: OpsTab.more,
                  onOpenAccount: () => context.push(opsAccountPath),
                  onOpenDevices: () => context.go(opsDevicesPath),
                ),
                routes: [
                  GoRoute(
                    path: 'devices',
                    builder: (context, state) => OperationsSoonPage(
                      kind: OpsSoon.devices,
                      onBack: () => _backTo(context, opsMorePath),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      if (enableGallery)
        GoRoute(
          path: galleryPath,
          builder: (context, state) => const GalleryPage(),
        ),
      if (showDebugPanel)
        GoRoute(
          path: debugMocksPath,
          builder: (context, _) => debugPanelBuilder(context),
        ),
    ],
  );
}

/// El identificador de la ruta; uno ilegible (`-1`) no existe en ninguna
/// distribución y la pantalla lo dice.
int _idOf(GoRouterState state, String name) =>
    int.tryParse(state.pathParameters[name] ?? '') ?? -1;

/// ¿La sesión es de un administrador de universidad (`ADMIN`)? Solo él
/// gestiona la distribución, los accesos, los dominios y el equipo.
bool _isAdmin(AuthCubit authCubit) {
  final auth = authCubit.state;
  return auth is Authenticated && auth.session.role == UserRole.admin;
}

/// Volver: a la pantalla anterior; con un enlace directo (sin anterior), a
/// Zonas.
void _back(BuildContext context) => _backTo(context, zonesPath);

/// Volver: a la pantalla anterior; con un enlace directo (sin anterior), a
/// [fallback].
void _backTo(BuildContext context, String fallback) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallback);
  }
}

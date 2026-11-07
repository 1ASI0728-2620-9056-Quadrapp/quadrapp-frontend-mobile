// US01, US02, US03
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:quadrapp_mobile/app/config/app_config.dart';
import 'package:quadrapp_mobile/app/debug/mock_controls_page.dart';
import 'package:quadrapp_mobile/app/di/alerts_module.dart';
import 'package:quadrapp_mobile/app/di/arrival_module.dart';
import 'package:quadrapp_mobile/app/di/auth_module.dart';
import 'package:quadrapp_mobile/app/di/eta_module.dart';
import 'package:quadrapp_mobile/app/di/forecast_module.dart';
import 'package:quadrapp_mobile/app/di/sede_module.dart';
import 'package:quadrapp_mobile/app/di/zones_module.dart';
import 'package:quadrapp_mobile/app/mocks/mock_controls.dart';
import 'package:quadrapp_mobile/app/mocks/mock_world.dart';
import 'package:quadrapp_mobile/app/router/app_router.dart';
import 'package:quadrapp_mobile/app/session/pending_removal_retrier.dart';
import 'package:quadrapp_mobile/app/session/session_expiry_coordinator.dart';
import 'package:quadrapp_mobile/contexts/iam/application/usecases/refresh_session.dart';
import 'package:quadrapp_mobile/contexts/iam/presentation/cubit/auth_cubit.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/application/usecases/list_parking_lots.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';

/// Arranca lo que debe estar vivo desde que abre la app (la DI solo registra):
///
/// - [SessionExpiryCoordinator]: escucha la expiración de sesión y llama a
///   `SignOut(sessionExpired)`. Cuando el dispositivo ya está limpio, el estado
///   de sesión pasa a "sin sesión" (`AuthCubit.sessionEnded`) y el router
///   lleva a `/login?reason=expired`.
/// - [AuthCubit.restore]: lee la sesión guardada, sin pedir un código ni llamar
///   al servidor (US01 esc. 6). No se espera: la primera pantalla es el
///   skeleton.
/// - [PendingRemovalRetrier]: reintenta la baja pendiente del token push ahora
///   y cada vez que la app vuelve a primer plano. El primer intento no se
///   espera: no debe retrasar la primera pantalla, y un fallo no se propaga.
/// - Con `USE_MOCKS=true`, el simulador de espacios (se apaga con
///   [startSimulator], en las pruebas).
void startAppServices(GetIt locator, {bool startSimulator = true}) {
  final expiry = locator<SessionExpiryCoordinator>()..start();
  final auth = locator<AuthCubit>();
  expiry.addListener(() {
    if (expiry.hasExpired) auth.sessionEnded();
  });
  unawaited(auth.restore());
  unawaited(locator<PendingRemovalRetrier>().start());
  if (startSimulator && locator<AppConfig>().useMocks) {
    locator<MockWorld>().startSimulator();
  }
}

/// El router de la app con las dependencias del contenedor. `bootstrap` y las
/// pruebas lo comparten, así no hay dos cableados distintos.
///
/// El panel de depuración solo se registra con [enableDebugPanel] (debug) **y**
/// mocks: sin `MockControls` no tiene nada que controlar.
GoRouter createRouterFrom(
  GetIt locator, {
  bool enableGallery = kDebugMode,
  bool enableDebugPanel = kDebugMode,
}) {
  return createAppRouter(
    authCubit: locator<AuthCubit>(),
    expiry: locator<SessionExpiryCoordinator>(),
    createLoginCubit: locator<CreateLoginCubit>(),
    createVerifyCodeCubit: locator<CreateVerifyCodeCubit>(),
    createSignOutCubit: locator<CreateSignOutCubit>(),
    createArrivalCubit: locator<CreateArrivalCubit>(),
    createSedeCubit: locator<CreateSedeCubit>(),
    createEtaCubit: locator<CreateEtaCubit>(),
    createZonesCubit: locator<CreateZonesCubit>(),
    createForecastCubit: locator<CreateForecastCubit>(),
    createAlertsCubit: locator<CreateAlertsCubit>(),
    clock: locator<Clock>(),
    enableGallery: enableGallery,
    enableDebugPanel: enableDebugPanel,
    debugPanelBuilder: enableDebugPanel && locator<AppConfig>().useMocks
        ? (context) => MockControlsPage(
            controls: locator<MockControls>(),
            refreshSession: locator<RefreshSession>(),
            listParkingLots: locator<ListParkingLots>(),
            resetData: locator<MockWorld>().reset,
          )
        : null,
  );
}

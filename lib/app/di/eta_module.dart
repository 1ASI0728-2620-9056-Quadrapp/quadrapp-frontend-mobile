import 'package:get_it/get_it.dart';
import 'package:quadrapp_mobile/app/config/app_config.dart';
import 'package:quadrapp_mobile/app/di/registrar.dart';
import 'package:quadrapp_mobile/composition/eta/eta_cubit.dart';

/// Crea el cubit del tiempo de llegada (compartido por Inicio y Predicción):
/// el shell del Conductor lo crea al entrar y lo cierra al salir.
typedef CreateEtaCubit = EtaCubit Function();

/// Composición del tiempo de llegada (US13, US14): la fábrica del cubit que
/// decide el ETA (lo manual manda; si no, el estimado en el dispositivo).
void registerEtaModule(GetIt locator, AppConfig config) {
  locator.addValue<CreateEtaCubit>(
    () => EtaCubit(
      estimateArrivalEta: locator(),
      getPermissionStatus: locator(),
      requestPermission: locator(),
      getPreferences: locator(),
      savePreferences: locator(),
      clock: locator(),
      trafficAvailable: config.hasTrafficProvider,
    ),
  );
}

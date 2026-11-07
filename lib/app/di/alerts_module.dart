import 'package:get_it/get_it.dart';
import 'package:quadrapp_mobile/app/di/registrar.dart';
import 'package:quadrapp_mobile/composition/alerts/alerts_cubit.dart';

/// Crea el cubit de Alertas (`/alerts`). Cada pantalla tiene el suyo: el
/// router lo crea al entrar a la ruta y lo cierra al salir.
typedef CreateAlertsCubit = AlertsCubit Function();

/// Composición de Alertas y preferencias (US23, US24, US33): la fábrica del
/// cubit que usa los casos de uso de `notifications` (preferencias, franjas y
/// habilitar el teléfono).
void registerAlertsModule(GetIt locator) {
  locator.addValue<CreateAlertsCubit>(
    () => AlertsCubit(
      getPreferences: locator(),
      savePreferences: locator(),
      listSubscriptions: locator(),
      createSubscription: locator(),
      setActive: locator(),
      removeSubscription: locator(),
      activateDevice: locator(),
    ),
  );
}

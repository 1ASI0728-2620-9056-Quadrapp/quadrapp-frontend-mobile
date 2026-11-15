import 'package:get_it/get_it.dart';
import 'package:quadrapp_mobile/app/di/registrar.dart';
import 'package:quadrapp_mobile/composition/arrival/arrival_cubit.dart';

/// Crea el cubit de Inicio (`/home`). Cada pantalla tiene el suyo: el router lo
/// crea al entrar a la ruta y lo cierra al salir.
typedef CreateArrivalCubit = ArrivalCubit Function();

/// Composición de Inicio, «Tu llegada» (US05, US07, US09 a US15, US36): la
/// fábrica del cubit que combina `occupancy` (la ocupación en vivo y la
/// conexión) con `prediction_advisory` (la asesoría, los horizontes y la
/// próxima liberación).
void registerArrivalModule(GetIt locator) {
  locator.addValue<CreateArrivalCubit>(
    () => ArrivalCubit(
      getLotOccupancy: locator(),
      requestArrivalAdvice: locator(),
      recalculateAdvice: locator(),
      getNextAvailability: locator(),
      watchLotFeed: locator(),
      clock: locator(),
    ),
  );
}

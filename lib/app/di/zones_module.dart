import 'package:get_it/get_it.dart';
import 'package:quadrapp_mobile/app/di/registrar.dart';
import 'package:quadrapp_mobile/composition/zones/zones_cubit.dart';

/// Crea el cubit de Zonas. Es **uno solo** para las pantallas de Zonas (la
/// sede, el pabellón y el nivel): lo crea el alcance del Conductor y lo cierra
/// al salir.
typedef CreateZonesCubit = ZonesCubit Function();

/// Composición de Zonas (US06, US07, US08): la fábrica del cubit que combina
/// `parking_configuration` (la distribución en pabellones y niveles) con
/// `occupancy` (la ocupación en vivo y sus conteos por pabellón y por nivel).
void registerZonesModule(GetIt locator) {
  locator.addValue<CreateZonesCubit>(
    () => ZonesCubit(
      getLotLayout: locator(),
      getLotOccupancy: locator(),
      watchLotFeed: locator(),
      getZoneSummary: locator(),
      getLevelSummary: locator(),
    ),
  );
}

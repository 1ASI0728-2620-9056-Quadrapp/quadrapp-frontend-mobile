import 'package:get_it/get_it.dart';
import 'package:quadrapp_mobile/app/di/registrar.dart';
import 'package:quadrapp_mobile/composition/sede/sede_cubit.dart';

/// Crea el cubit de la sede (compartido por Inicio, Zonas y Predicción): el
/// shell del Conductor lo crea al entrar y lo cierra al salir.
typedef CreateSedeCubit = SedeCubit Function();

/// Composición de la sede (US04): la fábrica del cubit que combina la lista de
/// estacionamientos con el que el conductor eligió.
void registerSedeModule(GetIt locator) {
  locator.addValue<CreateSedeCubit>(
    () => SedeCubit(
      listParkingLots: locator(),
      getSelectedLot: locator(),
      selectLot: locator(),
    ),
  );
}

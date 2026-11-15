import 'package:get_it/get_it.dart';
import 'package:quadrapp_mobile/app/di/registrar.dart';
import 'package:quadrapp_mobile/composition/forecast/forecast_cubit.dart';

/// Crea el cubit de Predicción (`/forecast`). Cada pantalla tiene el suyo: el
/// router lo crea al entrar a la ruta y lo cierra al salir.
typedef CreateForecastCubit = ForecastCubit Function();

/// Composición de Predicción (US09 a US12, US15): la fábrica del cubit que
/// combina los pronósticos de `prediction_advisory` con la asesoría de llegada
/// a cada horizonte.
void registerForecastModule(GetIt locator) {
  locator.addValue<CreateForecastCubit>(
    () => ForecastCubit(
      getLotForecasts: locator(),
      requestArrivalAdvice: locator(),
    ),
  );
}

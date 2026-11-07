import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quadrapp_mobile/app/di/sede_module.dart';
import 'package:quadrapp_mobile/app/di/zones_module.dart';
import 'package:quadrapp_mobile/composition/sede/sede_cubit.dart';
import 'package:quadrapp_mobile/composition/zones/zones_cubit.dart';

/// Lo que comparten las pestañas de Operación: el estacionamiento elegido
/// ([SedeCubit], el mismo selector que usa el Conductor) y su distribución con
/// la ocupación en vivo ([ZonesCubit], para Estacionamientos, la zona y el
/// nivel). Se crea al entrar a la experiencia de Operación y se cierra al
/// salir (el cierre de sesión lo descarta).
class OperationsScope extends StatelessWidget {
  const OperationsScope({
    required this.createSedeCubit,
    required this.createZonesCubit,
    required this.child,
    super.key,
  });

  final CreateSedeCubit createSedeCubit;
  final CreateZonesCubit createZonesCubit;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SedeCubit>(
          create: (_) {
            final cubit = createSedeCubit();
            unawaited(cubit.load());
            return cubit;
          },
        ),
        BlocProvider<ZonesCubit>(create: (_) => createZonesCubit()),
      ],
      child: child,
    );
  }
}

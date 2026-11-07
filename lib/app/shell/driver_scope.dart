import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quadrapp_mobile/app/di/eta_module.dart';
import 'package:quadrapp_mobile/app/di/sede_module.dart';
import 'package:quadrapp_mobile/app/di/zones_module.dart';
import 'package:quadrapp_mobile/composition/eta/eta_cubit.dart';
import 'package:quadrapp_mobile/composition/sede/sede_cubit.dart';
import 'package:quadrapp_mobile/composition/sede/sede_state.dart';
import 'package:quadrapp_mobile/composition/zones/zones_cubit.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

/// Lo que comparten las pestañas del Conductor (Inicio, Zonas y Predicción):
/// la sede elegida ([SedeCubit]), el tiempo de llegada ([EtaCubit]) y la
/// distribución con su ocupación en vivo ([ZonesCubit], para las pantallas de
/// Zonas). Se crea
/// al entrar a la experiencia del Conductor y se cierra al salir (el cierre de
/// sesión los descarta).
///
/// Cuando cambia la sede elegida, el ETA se recalcula con las coordenadas de la
/// nueva (sin coordenadas, solo hay ETA manual).
class DriverScope extends StatelessWidget {
  const DriverScope({
    required this.createSedeCubit,
    required this.createEtaCubit,
    required this.createZonesCubit,
    required this.child,
    super.key,
  });

  final CreateSedeCubit createSedeCubit;
  final CreateEtaCubit createEtaCubit;
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
        BlocProvider<EtaCubit>(create: (_) => createEtaCubit()),
        BlocProvider<ZonesCubit>(create: (_) => createZonesCubit()),
      ],
      child: BlocListener<SedeCubit, ViewState<SedeSelection>>(
        listenWhen: (before, after) =>
            _selected(before)?.id != _selected(after)?.id,
        listener: (context, state) => unawaited(
          context.read<EtaCubit>().setDestination(_selected(state)),
        ),
        child: child,
      ),
    );
  }

  static ParkingLot? _selected(ViewState<SedeSelection> state) =>
      state is ViewData<SedeSelection> ? state.data.selected : null;
}

// US04, US06
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quadrapp_mobile/composition/sede/sede_cubit.dart';
import 'package:quadrapp_mobile/composition/sede/sede_state.dart';
import 'package:quadrapp_mobile/composition/zones/zones_cubit.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

/// Mantiene el [ZonesCubit] (compartido por Zonas, el pabellón y el nivel)
/// en la sede elegida: la toma al abrir la pantalla (también al llegar por un
/// enlace) y la cambia cuando el conductor elige otra.
class ZonesSync extends StatefulWidget {
  const ZonesSync({required this.child, super.key});

  final Widget child;

  @override
  State<ZonesSync> createState() => _ZonesSyncState();
}

class _ZonesSyncState extends State<ZonesSync> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _sync(context.read<SedeCubit>().state);
    });
  }

  void _sync(ViewState<SedeSelection> state) =>
      unawaited(context.read<ZonesCubit>().setLot(_selectedOf(state)));

  static ParkingLot? _selectedOf(ViewState<SedeSelection> state) =>
      state is ViewData<SedeSelection> ? state.data.selected : null;

  @override
  Widget build(BuildContext context) {
    return BlocListener<SedeCubit, ViewState<SedeSelection>>(
      listenWhen: (before, after) =>
          _selectedOf(before)?.id != _selectedOf(after)?.id,
      listener: (context, state) => _sync(state),
      child: widget.child,
    );
  }
}

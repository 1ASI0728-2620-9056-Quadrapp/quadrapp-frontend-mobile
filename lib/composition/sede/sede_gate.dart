// US04
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quadrapp_mobile/composition/sede/live_status.dart';
import 'package:quadrapp_mobile/composition/sede/sede_cubit.dart';
import 'package:quadrapp_mobile/composition/sede/sede_prompt.dart';
import 'package:quadrapp_mobile/composition/sede/sede_state.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

/// Lo que ven las pantallas del Conductor antes de tener una sede: cargando
/// las sedes ([skeleton]), la institución sin sedes, un error recuperable y
/// la invitación a elegir una. Con una sede elegida, [builder] arma el
/// contenido.
class SedeGate extends StatelessWidget {
  const SedeGate({required this.skeleton, required this.builder, super.key});

  /// Lo que se ve mientras llegan las sedes.
  final Widget skeleton;
  final Widget Function(BuildContext context, ParkingLot lot) builder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<SedeCubit, ViewState<SedeSelection>>(
      builder: (context, sede) {
        final selection = switch (sede) {
          ViewData(:final data) => data,
          ViewLoading(:final previous) => previous,
          ViewError(:final previous) => previous,
          _ => null,
        };
        if (selection == null) {
          return switch (sede) {
            ViewEmpty() => Padding(
              padding: const EdgeInsets.only(top: QaSpacing.xxxl),
              child: QaEmptyState(
                illustration: QaIllustrationKind.parking,
                title: l10n.lots_emptyTitle,
                message: l10n.lots_emptyMessage,
              ),
            ),
            ViewError(:final failure) => Padding(
              padding: const EdgeInsets.only(top: QaSpacing.xxxl),
              child: QaErrorState(
                title: l10n.sede_errorTitle,
                message: loadErrorText(l10n, failure),
                retryLabel: l10n.lots_retry,
                onRetry: () => unawaited(context.read<SedeCubit>().load()),
              ),
            ),
            _ => skeleton,
          };
        }
        final lot = selection.selected;
        if (lot == null) {
          return Padding(
            padding: const EdgeInsets.only(top: QaSpacing.xl),
            child: SedePrompt(selection: selection),
          );
        }
        return builder(context, lot);
      },
    );
  }
}

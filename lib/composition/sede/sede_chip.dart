// US04 (la sede que ve el conductor)
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quadrapp_mobile/composition/sede/sede_cubit.dart';
import 'package:quadrapp_mobile/composition/sede/sede_option.dart';
import 'package:quadrapp_mobile/composition/sede/sede_state.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

/// La sede elegida, como una píldora tocable bajo la barra superior de Inicio,
/// Zonas y Predicción: un pin, el nombre y una flecha. Al tocarla abre la
/// ventana para elegir otra ([showSedePicker]). Sin sede elegida dice «Elegir
/// sede». Mientras carga muestra un bloque gris; si no hay sedes o fallaron,
/// no muestra nada (la pantalla ya lo explica).
class SedeChip extends StatelessWidget {
  const SedeChip({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SedeCubit, ViewState<SedeSelection>>(
      builder: (context, state) {
        final data = switch (state) {
          ViewData(:final data) => data,
          ViewLoading(:final previous) => previous,
          ViewError(:final previous) => previous,
          _ => null,
        };
        if (data == null) {
          if (state is ViewInitial || state is ViewLoading) {
            return const QaSkeleton(width: 140, height: 36);
          }
          return const SizedBox.shrink();
        }
        return _Pill(
          label:
              data.selected?.name ?? AppLocalizations.of(context).sede_choose,
          onTap: () => unawaited(showSedePicker(context)),
        );
      },
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;
    return Semantics(
      button: true,
      label: l10n.sede_chipLabel(label),
      excludeSemantics: true,
      onTap: onTap,
      child: QaPressScale(
        child: Material(
          color: colors.surface,
          shape: StadiumBorder(side: BorderSide(color: colors.paint)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: QaSpacing.minTapTarget,
              ),
              child: Padding(
                padding: const EdgeInsets.only(
                  left: QaSpacing.md,
                  right: QaSpacing.sm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: colors.primary,
                    ),
                    const SizedBox(width: QaSpacing.xs + 2),
                    Flexible(
                      child: Text(label, style: theme.textTheme.labelMedium),
                    ),
                    Icon(
                      Icons.expand_more_rounded,
                      size: 20,
                      color: colors.onSurfaceMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Abre la ventana inferior para elegir la sede: una opción por sede, con la
/// elegida marcada. Elegir confirma con una háptica ligera, guarda la sede y
/// cierra la ventana.
Future<void> showSedePicker(BuildContext context) {
  final cubit = context.read<SedeCubit>();
  final l10n = AppLocalizations.of(context);
  return showQaBottomSheet<void>(
    context,
    builder: (sheetContext) => BlocProvider<SedeCubit>.value(
      value: cubit,
      child: QaBottomSheet(
        title: l10n.sede_sheetTitle,
        subtitle: l10n.sede_sheetSubtitle,
        closeLabel: l10n.sede_close,
        child: BlocBuilder<SedeCubit, ViewState<SedeSelection>>(
          builder: (context, state) {
            final data = switch (state) {
              ViewData(:final data) => data,
              _ => null,
            };
            if (data == null) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final lot in data.lots) ...[
                  SedeOption(
                    lot: lot,
                    selected: lot.id == data.selected?.id,
                    onTap: () {
                      QaHaptics.confirm();
                      unawaited(cubit.select(lot.id));
                      Navigator.of(sheetContext).pop();
                    },
                  ),
                  const SizedBox(height: QaSpacing.sm),
                ],
              ],
            );
          },
        ),
      ),
    ),
  );
}

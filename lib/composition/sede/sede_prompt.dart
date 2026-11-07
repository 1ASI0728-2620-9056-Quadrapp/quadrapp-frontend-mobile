// US04 (la sede que ve el conductor)
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quadrapp_mobile/composition/sede/sede_cubit.dart';
import 'package:quadrapp_mobile/composition/sede/sede_option.dart';
import 'package:quadrapp_mobile/composition/sede/sede_state.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';

/// Lo que ven Inicio, Zonas y Predicción cuando el conductor todavía no eligió
/// su sede: una ilustración, una pregunta corta y la lista de sedes para
/// elegir con un toque. Elegir guarda la sede (queda para la próxima vez) y la
/// pantalla se rellena sola.
class SedePrompt extends StatelessWidget {
  const SedePrompt({required this.selection, super.key});

  final SedeSelection selection;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;
    final cubit = context.read<SedeCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: QaIllustration(kind: QaIllustrationKind.parking)),
        const SizedBox(height: QaSpacing.lg),
        Semantics(
          header: true,
          child: Text(
            l10n.sede_promptTitle,
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: QaSpacing.sm),
        Text(
          l10n.sede_promptMessage,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colors.onSurfaceMuted,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: QaSpacing.xl),
        for (final lot in selection.lots) ...[
          SedeOption(
            lot: lot,
            selected: false,
            onTap: () {
              QaHaptics.confirm();
              unawaited(cubit.select(lot.id));
            },
          ),
          const SizedBox(height: QaSpacing.sm),
        ],
      ],
    );
  }
}

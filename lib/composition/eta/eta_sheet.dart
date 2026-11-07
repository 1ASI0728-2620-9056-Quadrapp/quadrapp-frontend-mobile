// US13, US14, TS08
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quadrapp_mobile/composition/eta/eta_cubit.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/prediction_advisory.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';

/// Opciones rápidas del tiempo de llegada, en minutos.
const List<int> etaQuickMinutes = [10, 15, 20, 30, 45, 60];

/// Abre la ventana «¿Cuándo llegas?»: el cálculo automático con la ubicación
/// (que se puede apagar, con la explicación de qué se comparte antes de pedir
/// el permiso), el tráfico en tiempo real (aparte, porque envía la ubicación
/// aproximada a Google) o elegir el tiempo a mano con opciones rápidas y un
/// ajuste de 5 en 5. Cada cambio se aplica al instante; «Listo» cierra la
/// ventana.
Future<void> showEtaSheet(BuildContext context) {
  final cubit = context.read<EtaCubit>();
  final l10n = AppLocalizations.of(context);
  return showQaBottomSheet<void>(
    context,
    builder: (sheetContext) => BlocProvider<EtaCubit>.value(
      value: cubit,
      child: QaBottomSheet(
        title: l10n.eta_sheetTitle,
        closeLabel: l10n.eta_close,
        footer: QaButton(
          label: l10n.eta_done,
          expand: true,
          onPressed: () => Navigator.of(sheetContext).pop(),
        ),
        child: const _EtaSheetBody(),
      ),
    ),
  );
}

class _EtaSheetBody extends StatelessWidget {
  const _EtaSheetBody();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;
    final cubit = context.read<EtaCubit>();

    return BlocBuilder<EtaCubit, EtaState>(
      builder: (context, state) {
        final estimate = state.estimate;
        final locationBlocked =
            state.permission == LocationPermissionStatus.deniedForever ||
            state.permission == LocationPermissionStatus.serviceDisabled;
        final locationNote = switch (state.permission) {
          _ when !state.hasDestination => l10n.eta_noPosition,
          LocationPermissionStatus.deniedForever => l10n.eta_locationBlocked,
          LocationPermissionStatus.serviceDisabled => l10n.eta_locationOff,
          _ => null,
        };
        final canAutomate = state.hasDestination && !locationBlocked;
        // Los minutos del ajuste: el ETA vigente (lo manual baja con el
        // reloj), o lo que eligió, o 20.
        final shown = estimate?.minutes.value ?? state.manualMinutes ?? 20;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _AutomaticCard(
              state: state,
              note: state.autoEnabled ? locationNote : null,
              canAutomate: canAutomate,
              onAutoChanged: (enabled) {
                QaHaptics.confirm();
                unawaited(cubit.setAutoEnabled(enabled: enabled));
              },
              onTrafficChanged: (enabled) {
                QaHaptics.confirm();
                unawaited(cubit.setTrafficEnabled(enabled: enabled));
              },
              onAllowLocation: () {
                QaHaptics.confirm();
                unawaited(cubit.useLocation());
              },
            ),
            const SizedBox(height: QaSpacing.xl),
            Semantics(
              header: true,
              child: Text(
                l10n.eta_manualTitle,
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: QaSpacing.md),
            // Primero el valor, grande, con su ajuste fino; los atajos debajo.
            _Stepper(
              minutes: shown,
              onChanged: (minutes) => unawaited(cubit.chooseManual(minutes)),
            ),
            const SizedBox(height: QaSpacing.sm),
            Text(
              l10n.eta_stepHint,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: QaSpacing.md),
            Wrap(
              spacing: QaSpacing.sm,
              runSpacing: QaSpacing.sm,
              children: [
                for (final minutes in etaQuickMinutes)
                  _MinutesChip(
                    minutes: minutes,
                    selected: state.manualMinutes == minutes,
                    onSelected: () {
                      QaHaptics.confirm();
                      unawaited(cubit.chooseManual(minutes));
                    },
                  ),
              ],
            ),
            if (state.isManual) ...[
              const SizedBox(height: QaSpacing.md),
              Text(
                l10n.eta_manualCountdown,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceMuted,
                ),
              ),
              if (state.autoEnabled && canAutomate) ...[
                const SizedBox(height: QaSpacing.sm),
                QaButton(
                  label: l10n.eta_backToAuto,
                  variant: QaButtonVariant.tonal,
                  icon: Icons.my_location_rounded,
                  expand: true,
                  onPressed: () {
                    QaHaptics.confirm();
                    unawaited(cubit.useLocation());
                  },
                ),
              ],
            ],
            const SizedBox(height: QaSpacing.lg),
            QaBanner(
              kind: QaBannerKind.info,
              icon: Icons.verified_user_outlined,
              message: l10n.eta_locationBody,
            ),
          ],
        );
      },
    );
  }
}

/// Cómo se calcula el tiempo de llegada: el modo automático (la ubicación del
/// teléfono, que se puede apagar) y, dentro de él, el tráfico en tiempo real
/// (que envía la ubicación aproximada a Google y por eso se enciende aparte,
/// con la explicación a la vista). Dice cuál es el tiempo de ahora y de dónde
/// sale; si no se puede (bloqueada, apagada, la sede sin coordenadas, más de 2
/// horas), dice por qué en lugar de un interruptor que no hace nada.
class _AutomaticCard extends StatelessWidget {
  const _AutomaticCard({
    required this.state,
    required this.note,
    required this.canAutomate,
    required this.onAutoChanged,
    required this.onTrafficChanged,
    required this.onAllowLocation,
  });

  final EtaState state;
  final String? note;
  final bool canAutomate;
  final ValueChanged<bool> onAutoChanged;
  final ValueChanged<bool> onTrafficChanged;
  final VoidCallback onAllowLocation;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;
    final estimate = state.estimate;
    final source = switch (estimate?.source) {
      EtaSource.manual => l10n.eta_sourceManual,
      EtaSource.traffic => l10n.eta_sourceTraffic,
      EtaSource.device => l10n.eta_sourceDevice,
      null => null,
    };
    final summary = estimate != null && source != null
        ? l10n.eta_currentSummary(estimate.minutes.value, source)
        : state.issue == EtaIssue.tooFar
        ? l10n.eta_tooFar
        : null;

    return QaCard(
      padding: const EdgeInsets.symmetric(
        horizontal: QaSpacing.lg,
        vertical: QaSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          QaSwitchRow(
            icon: Icons.my_location_rounded,
            title: l10n.eta_autoTitle,
            help: state.autoEnabled ? l10n.eta_autoOn : l10n.eta_autoOff,
            value: state.autoEnabled,
            // Sin poder usar la ubicación no se puede encender, pero apagar
            // siempre se puede.
            onChanged: canAutomate || state.autoEnabled ? onAutoChanged : null,
          ),
          if (state.autoEnabled && state.trafficAvailable) ...[
            const Divider(height: 1),
            QaSwitchRow(
              icon: Icons.traffic_rounded,
              title: l10n.eta_trafficTitle,
              help: state.trafficEnabled
                  ? l10n.eta_trafficOn
                  : l10n.eta_trafficOff,
              value: state.trafficEnabled,
              onChanged: canAutomate ? onTrafficChanged : null,
            ),
          ],
          if (summary != null || note != null || state.canUseLocation) ...[
            const Divider(height: 1),
            const SizedBox(height: QaSpacing.md),
            if (summary != null)
              Semantics(
                liveRegion: true,
                child: Text(summary, style: theme.textTheme.titleSmall),
              ),
            if (note != null) ...[
              const SizedBox(height: QaSpacing.sm),
              Text(
                note!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.limitedText,
                ),
              ),
            ],
            if (state.autoEnabled && state.canUseLocation) ...[
              const SizedBox(height: QaSpacing.md),
              QaButton(
                label: l10n.eta_useLocation,
                icon: Icons.my_location_rounded,
                expand: true,
                onPressed: onAllowLocation,
              ),
            ],
            const SizedBox(height: QaSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _MinutesChip extends StatelessWidget {
  const _MinutesChip({
    required this.minutes,
    required this.selected,
    required this.onSelected,
  });

  final int minutes;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;
    return Semantics(
      button: true,
      selected: selected,
      label: l10n.eta_minutesSpoken(minutes),
      onTap: onSelected,
      excludeSemantics: true,
      child: Material(
        color: selected ? colors.primary : colors.surface,
        shape: StadiumBorder(
          side: BorderSide(color: selected ? colors.primary : colors.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onSelected,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: QaSpacing.minTapTarget,
              minHeight: QaSpacing.minTapTarget,
            ),
            // `widthFactor: 1`: la opción mide lo que su texto, no el ancho.
            child: Center(
              widthFactor: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: QaSpacing.lg),
                child: Text(
                  l10n.eta_minutesChip(minutes),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: selected ? colors.onPrimary : colors.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ajuste fino del tiempo, de 5 en 5 (de 5 a 120): la cifra grande al centro
/// y los botones de menos y más a los lados (48 dp).
class _Stepper extends StatelessWidget {
  const _Stepper({required this.minutes, required this.onChanged});

  final int minutes;
  final ValueChanged<int> onChanged;

  static const int step = 5;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;

    Widget button(String tooltip, IconData icon, VoidCallback? onPressed) =>
        IconButton(
          tooltip: tooltip,
          icon: Icon(icon),
          onPressed: onPressed,
          color: colors.onSurface,
          style: IconButton.styleFrom(
            fixedSize: const Size.square(QaSpacing.minTapTarget),
            shape: RoundedRectangleBorder(
              borderRadius: QaRadii.controlRadius,
              side: BorderSide(
                color: onPressed == null ? colors.paint : colors.outline,
              ),
            ),
          ),
        );

    return Row(
      children: [
        button(
          l10n.eta_less,
          Icons.remove_rounded,
          minutes > step ? () => onChanged(minutes - step) : null,
        ),
        Expanded(
          child: Semantics(
            liveRegion: true,
            label: l10n.eta_minutesSpoken(minutes),
            excludeSemantics: true,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '$minutes',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                  TextSpan(
                    text: ' ${l10n.eta_minutesUnit}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        button(
          l10n.eta_more,
          Icons.add_rounded,
          minutes + step <= EtaMinutes.max
              ? () => onChanged(minutes + step)
              : null,
        ),
      ],
    );
  }
}

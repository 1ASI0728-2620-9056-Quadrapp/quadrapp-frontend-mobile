// US13, US14
import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/composition/eta/eta_cubit.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/prediction_advisory.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';

/// La tarjeta de petróleo de Predicción con el tiempo de llegada: «Si sales
/// ahora · Llegas en 27 min» y de dónde sale (estimado en el dispositivo o
/// elegido por el conductor). Sin tiempo de llegada, invita a elegirlo. Toda
/// la tarjeta abre «¿Cuándo llegas?» ([onTap]).
class EtaHero extends StatelessWidget {
  const EtaHero({
    required this.eta,
    required this.onTap,
    this.updatedAgo,
    super.key,
  });

  final EtaState eta;
  final VoidCallback onTap;

  /// «Tu llegada se actualizó hace 1 min»: cuándo se calculó por última vez el
  /// tiempo (lo arma la pantalla con el reloj monótono); sin él, no se dice.
  final String? updatedAgo;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;
    final estimate = eta.estimate;

    final (caption, headline, source) = switch (estimate) {
      final estimate? => (
        estimate.isEstimated
            ? l10n.forecast_ifLeaveNow
            : l10n.forecast_yourArrivalTime,
        estimate.minutes.value == 0
            ? l10n.home_arriveNow
            : l10n.forecast_arriveIn(estimate.minutes.value),
        switch (estimate.source) {
          EtaSource.manual => l10n.forecast_etaManual,
          EtaSource.traffic => l10n.forecast_etaTraffic,
          EtaSource.device => l10n.forecast_etaDevice,
        },
      ),
      null when eta.isEstimating => (
        l10n.forecast_yourArrivalTime,
        l10n.forecast_etaEstimating,
        '',
      ),
      null when eta.issue == EtaIssue.tooFar => (
        l10n.forecast_tooFar,
        l10n.forecast_etaPrompt,
        '',
      ),
      null => (l10n.forecast_etaPromptCaption, l10n.forecast_etaPrompt, ''),
    };

    return QaCard(
      hero: true,
      onTap: onTap,
      padding: const EdgeInsets.all(QaSpacing.xl),
      semanticLabel: [
        l10n.forecast_heroSemantics(caption, headline, source),
        ?updatedAgo,
      ].join('. '),
      semanticHint: l10n.eta_sheetTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            caption,
            style: theme.textTheme.titleSmall?.copyWith(
              color: colors.onBrandMuted,
            ),
          ),
          const SizedBox(height: QaSpacing.xs),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: QaSpacing.sm,
            children: [
              Text(
                headline,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: colors.onBrand,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (source.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: QaSpacing.xs),
                  child: Text(
                    source,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onBrandMuted,
                    ),
                  ),
                ),
            ],
          ),
          if (updatedAgo != null) ...[
            const SizedBox(height: QaSpacing.sm),
            Text(
              updatedAgo!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onBrandMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// US05, US09, US13, US14, US15, US36
import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/composition/arrival/arrival_copy.dart';
import 'package:quadrapp_mobile/composition/arrival/arrival_state.dart';
import 'package:quadrapp_mobile/composition/arrival/lot_age_text.dart';
import 'package:quadrapp_mobile/composition/eta/eta_copy.dart';
import 'package:quadrapp_mobile/composition/eta/eta_cubit.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/prediction_advisory.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';
import 'package:quadrapp_mobile/core/time/app_time_formatter.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';

/// La tarjeta de petróleo de Inicio: la categoría y la probabilidad de
/// encontrar espacio al llegar, una frase clara y tres cifras (cuándo llegas,
/// cuántos libres hay ahora y cuánto confiar).
///
/// - Sin tiempo de llegada, en lugar de la asesoría pide elegirlo.
/// - Con la asesoría no disponible, lo dice y deja ver la ocupación.
/// - Una asesoría de confianza baja lleva su advertencia (US12, US13 esc. 3).
/// - Llena, dice cuándo se espera que se libere un espacio (US36).
/// - Toda cifra de ocupación muestra su antigüedad y toda predicción, su
///   confianza y hace cuánto se generó, con la hora del servidor.
/// - Los espacios sin datos nunca cuentan como libres: «de 420 espacios» es la
///   capacidad y los sin datos van aparte.
class ArrivalHeroCard extends StatelessWidget {
  const ArrivalHeroCard({
    required this.overview,
    required this.eta,
    required this.clock,
    required this.onChangeEta,
    super.key,
  });

  final ArrivalOverview overview;
  final EtaState eta;
  final Clock clock;

  /// Abre «¿Cuándo llegas?».
  final VoidCallback onChangeEta;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;
    final advice = overview.advice;
    final category = overview.adviceStatus == AdviceStatus.available
        ? advice?.category
        : null;
    final occupancy = overview.occupancy;

    final statement = switch (overview.adviceStatus) {
      AdviceStatus.needsEta =>
        eta.issue == EtaIssue.tooFar
            ? l10n.home_statementTooFar
            : l10n.home_statementNeedsEta,
      AdviceStatus.unavailable => l10n.home_statementUnavailable,
      AdviceStatus.available =>
        category == null
            ? l10n.home_statementUnavailable
            : categoryStatement(l10n, category),
    };

    return QaCard(
      hero: true,
      padding: const EdgeInsets.all(QaSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (category != null ||
              overview.adviceStatus == AdviceStatus.unavailable) ...[
            _TopRow(
              category: category,
              advice: advice,
              status: overview.adviceStatus,
            ),
            const SizedBox(height: QaSpacing.xl),
          ],
          Semantics(
            header: true,
            child: Text(
              statement,
              style: theme.textTheme.titleLarge?.copyWith(
                color: colors.onBrand,
              ),
            ),
          ),
          if (advice != null && advice.isLowConfidence && category != null) ...[
            const SizedBox(height: QaSpacing.md),
            _Note(
              icon: Icons.info_outline_rounded,
              text: l10n.home_lowConfidence,
            ),
          ],
          if (category != null && overview.lastChange != null) ...[
            _ChangeNote(change: overview.lastChange!, clock: clock),
          ],
          if (overview.adviceStatus == AdviceStatus.needsEta) ...[
            const SizedBox(height: QaSpacing.lg),
            QaButton(
              label: l10n.home_chooseEta,
              variant: QaButtonVariant.onBrand,
              icon: Icons.schedule_rounded,
              expand: true,
              onPressed: onChangeEta,
            ),
          ],
          const SizedBox(height: QaSpacing.lg),
          Divider(color: colors.onBrand.withValues(alpha: 0.24), height: 1),
          const SizedBox(height: QaSpacing.lg),
          _Stats(
            overview: overview,
            eta: eta,
            clock: clock,
            onChangeEta: onChangeEta,
          ),
          if (occupancy != null && occupancy.free == 0) ...[
            const SizedBox(height: QaSpacing.lg),
            _NextAvailability(next: overview.nextAvailability),
          ],
          if (occupancy != null) ...[
            const SizedBox(height: QaSpacing.lg),
            _Note(
              icon: Icons.schedule_rounded,
              text: l10n.lots_updatedAgo(
                lotAgeText(l10n, occupancy.freshness.age(clock)),
              ),
              muted: true,
            ),
          ],
          if (eta.estimate?.isEstimated == true && eta.updatedAt != null) ...[
            const SizedBox(height: QaSpacing.sm),
            _Note(
              icon: Icons.update_rounded,
              text: etaUpdatedText(l10n, _since(clock, eta.updatedAt!)),
              muted: true,
            ),
          ],
        ],
      ),
    );
  }
}

/// La categoría en una píldora y, a la derecha, la probabilidad.
class _TopRow extends StatelessWidget {
  const _TopRow({
    required this.category,
    required this.advice,
    required this.status,
  });

  final ArrivalCategory? category;
  final ArrivalAdvice? advice;
  final AdviceStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;
    final category = this.category;
    final advice = this.advice;

    final chip = category != null
        ? QaStatusChip(
            tone: toneOfCategory(category),
            label: categoryLabel(l10n, category),
          )
        : status == AdviceStatus.unavailable
        ? QaStatusChip(tone: QaTone.unknown, label: l10n.home_categoryNone)
        : null;
    final percent = category != null && advice != null
        ? Semantics(
            label: '${percentOf(advice.probabilityOfSpace)} %',
            excludeSemantics: true,
            child: Text(
              '${percentOf(advice.probabilityOfSpace)}%',
              style: theme.textTheme.displayMedium?.copyWith(
                color: colors.onBrand,
              ),
            ),
          )
        : null;
    if (chip == null && percent == null) return const SizedBox.shrink();

    final largeText = MediaQuery.textScalerOf(context).scale(16) >= 24;
    if (largeText) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ?chip,
          if (chip != null && percent != null)
            const SizedBox(height: QaSpacing.sm),
          ?percent,
        ],
      );
    }
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: chip ?? const SizedBox.shrink(),
          ),
        ),
        ?percent,
      ],
    );
  }
}

/// Una línea de texto sobre el petróleo, con su ícono.
class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text, this.muted = false});

  final IconData icon;
  final String text;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.qaColors;
    final color = muted ? colors.onBrandMuted : colors.onBrand;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: ExcludeSemantics(child: Icon(icon, size: 16, color: color)),
        ),
        const SizedBox(width: QaSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

/// Cuándo llegas, cuántos libres hay ahora y cuánto confiar. Con el texto
/// grande o un ancho corto, las tres cifras pasan una debajo de otra.
class _Stats extends StatelessWidget {
  const _Stats({
    required this.overview,
    required this.eta,
    required this.clock,
    required this.onChangeEta,
  });

  final ArrivalOverview overview;
  final EtaState eta;
  final Clock clock;
  final VoidCallback onChangeEta;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final occupancy = overview.occupancy;
    final advice = overview.advice;
    final estimate = eta.estimate;
    final locale = Localizations.localeOf(context).languageCode;
    final serverNow = overview.serverNow(clock);
    // «9:07 · con tráfico en vivo»: la hora a la que llegas (con la hora del
    // servidor, no la del teléfono) y de dónde sale el tiempo.
    final arrivalCaption = estimate == null
        ? l10n.eta_change
        : [
            if (serverNow != null)
              const AppTimeFormatter().formatTime(
                serverNow.add(Duration(minutes: estimate.minutes.value)),
                locale,
              ),
            switch (estimate.source) {
              EtaSource.manual => l10n.eta_sourceManual,
              EtaSource.traffic => l10n.eta_sourceTraffic,
              EtaSource.device => l10n.eta_sourceDevice,
            },
          ].join(' · ');

    final stats = <Widget>[
      if (overview.adviceStatus != AdviceStatus.needsEta)
        _Stat(
          label: l10n.home_statArrive,
          value: estimate == null
              ? '—'
              : estimate.minutes.value == 0
              ? l10n.home_arriveNow
              : l10n.home_minutes(estimate.minutes.value),
          caption: arrivalCaption,
          hint: l10n.eta_change,
          onTap: onChangeEta,
        ),
      _Stat(
        label: l10n.home_statNow,
        value: occupancy == null ? '—' : l10n.home_freeCount(occupancy.free),
        caption: occupancy == null
            ? null
            : occupancy.unknown > 0
            ? l10n.home_ofSpacesUnknown(occupancy.capacity, occupancy.unknown)
            : l10n.home_ofSpaces(occupancy.capacity),
      ),
      if (overview.adviceStatus != AdviceStatus.needsEta)
        _Stat(
          label: l10n.home_statConfidence,
          value: advice == null || !advice.isAvailable
              ? '—'
              : confidenceLabel(l10n, advice.confidence.level),
          caption: advice == null || !advice.isAvailable
              ? null
              : l10n.home_forecastAge(lotAgeText(l10n, advice.age(clock))),
        ),
    ];

    final narrow = MediaQuery.textScalerOf(context).scale(16) >= 22;
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = narrow || constraints.maxWidth < 280;
        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (index, stat) in stats.indexed) ...[
                if (index > 0) const SizedBox(height: QaSpacing.lg),
                stat,
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (index, stat) in stats.indexed) ...[
              if (index > 0) const SizedBox(width: QaSpacing.md),
              Expanded(child: stat),
            ],
          ],
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    this.caption,
    this.hint,
    this.onTap,
  });

  final String label;
  final String value;
  final String? caption;

  /// Pista de accesibilidad si se puede tocar.
  final String? hint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.qaColors;
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelSmall?.copyWith(
            color: colors.onBrandMuted,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: QaSpacing.xs),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(color: colors.onBrand),
        ),
        if (caption != null)
          Text(
            caption!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onBrandMuted,
            ),
          ),
      ],
    );

    if (onTap == null) {
      return Semantics(
        container: true,
        label: [label, value, ?caption].join(', '),
        excludeSemantics: true,
        child: content,
      );
    }
    return Semantics(
      container: true,
      button: true,
      label: [label, value, ?caption].join(', '),
      hint: hint,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: QaRadii.controlRadius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: QaSpacing.minTapTarget),
          child: content,
        ),
      ),
    );
  }
}

/// Cuándo se espera que se libere un espacio (US36), con la sede llena.
class _NextAvailability extends StatelessWidget {
  const _NextAvailability({required this.next});

  final NextAvailability? next;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = switch (next) {
      NextAvailabilityEstimate(:final minMinutes, :final maxMinutes) =>
        l10n.home_nextFree(minMinutes, maxMinutes),
      NextAvailabilityNoEstimate() => l10n.home_nextNone,
      NextAvailabilityNotApplicable() || null => null,
    };
    if (text == null) return const SizedBox.shrink();
    return _Note(icon: Icons.hourglass_bottom_rounded, text: text);
  }
}

/// Cuánto pasó desde [at] (reloj monótono), nunca negativo.
Duration _since(Clock clock, Duration at) {
  final elapsed = clock.monotonic() - at;
  return elapsed.isNegative ? Duration.zero : elapsed;
}

/// Qué cambió en la asesoría cuando cambió el tiempo de llegada: el ETA y la
/// probabilidad de antes y de ahora y, si cambió, la categoría. Es un panel
/// suave dentro de la tarjeta, sin ventana ni sonido: se ve unos minutos y lo
/// reemplaza el siguiente cambio. Se anuncia como región viva (cortés), con
/// texto y flecha: nunca solo con color.
class _ChangeNote extends StatelessWidget {
  const _ChangeNote({required this.change, required this.clock});

  final AdviceChange change;
  final Clock clock;

  @override
  Widget build(BuildContext context) {
    if (!change.isVisible(clock)) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;
    final before = percentOf(change.previousProbability);
    final now = percentOf(change.probability);
    final lines = [
      l10n.home_changeEta(change.eta, change.previousEta),
      if (before != now) l10n.home_changeChance(now, before),
      if (change.categoryChanged &&
          change.category != null &&
          change.previousCategory != null)
        l10n.home_changeCategory(
          categoryLabel(l10n, change.category!),
          categoryLabel(l10n, change.previousCategory!),
        ),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: QaSpacing.lg),
      child: Semantics(
        container: true,
        liveRegion: true,
        label: lines.join('. '),
        excludeSemantics: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.onBrand.withValues(alpha: 0.12),
            borderRadius: QaRadii.controlRadius,
          ),
          child: Padding(
            padding: const EdgeInsets.all(QaSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  change.improved
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 20,
                  color: colors.onBrand,
                ),
                const SizedBox(width: QaSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final line in lines)
                        Text(
                          line,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onBrand,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

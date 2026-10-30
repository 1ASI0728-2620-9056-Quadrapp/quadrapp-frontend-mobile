// US10, US11, US15
import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/composition/arrival/arrival_copy.dart';
import 'package:quadrapp_mobile/composition/arrival/arrival_state.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';

/// «Cómo puede cambiar»: la probabilidad de encontrar espacio si llegas dentro
/// de 15, 30, 45 o 60 minutos, en cuatro fichas con el color de su categoría
/// (verde, ámbar o rojo), un ícono y su texto: la categoría nunca va solo en
/// color. Un horizonte sin asesoría se ve neutro con «—». Cada ficha abre la
/// predicción ([onOpenForecast]).
///
/// Con el texto grande las fichas pasan de una fila de cuatro a dos filas de
/// dos.
class HorizonsCard extends StatelessWidget {
  const HorizonsCard({
    required this.horizons,
    required this.onOpenForecast,
    super.key,
  });

  final List<HorizonAdvice> horizons;
  final VoidCallback onOpenForecast;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final narrow = MediaQuery.textScalerOf(context).scale(16) >= 22;
    return QaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.home_changeTitle,
              style: theme.textTheme.titleSmall,
            ),
          ),
          const SizedBox(height: QaSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = narrow || constraints.maxWidth < 260 ? 2 : 4;
              const gap = QaSpacing.sm;
              final width =
                  (constraints.maxWidth - gap * (columns - 1)) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final item in horizons)
                    SizedBox(
                      width: width,
                      child: _Tile(item: item, onTap: onOpenForecast),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.item, required this.onTap});

  final HorizonAdvice item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;
    final minutes = item.horizon.minutes;
    final advice = item.advice;
    final category = item.isAvailable ? advice!.category : null;

    final tone = category == null ? null : toneOfCategory(category);
    final fill = tone == null ? colors.surfaceMuted : colors.fill(tone);
    final foreground = tone == null
        ? colors.onSurfaceMuted
        : colors.onFill(tone);
    final percent = category == null
        ? null
        : percentOf(advice!.probabilityOfSpace);
    final spoken = category == null
        ? l10n.home_horizonMissing(minutes)
        : l10n.home_horizonSpoken(
            minutes,
            percent!,
            categoryLabel(l10n, category),
          );

    return Semantics(
      container: true,
      button: true,
      label: spoken,
      hint: l10n.home_horizonsHint,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: fill,
        borderRadius: QaRadii.controlRadius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: QaSpacing.minTapTarget,
            ),
            // El ícono del tono va en la esquina: la ficha es angosta y la
            // etiqueta («15 min») debe quedar en una línea.
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: QaSpacing.sm,
                    vertical: QaSpacing.md,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.home_minutes(minutes),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceMuted,
                          ),
                        ),
                        const SizedBox(height: QaSpacing.xs),
                        Text(
                          percent == null ? '—' : '$percent%',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: foreground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (tone != null)
                  PositionedDirectional(
                    top: QaSpacing.xs,
                    end: QaSpacing.xs,
                    child: Icon(
                      QaStatusChip.iconOf(tone),
                      size: 12,
                      color: foreground,
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

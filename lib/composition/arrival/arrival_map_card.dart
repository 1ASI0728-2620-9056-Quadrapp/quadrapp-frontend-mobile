// US13 (mapa de la llegada); TS08 (la posición no llega a Quadrapp)
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quadrapp_mobile/composition/arrival/arrival_map_cubit.dart';
import 'package:quadrapp_mobile/composition/arrival/embedded_map.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';

/// «Cómo llegar»: el mapa de Google con la sede o, si el conductor usa su
/// ubicación, la ruta desde donde está. Es una vista previa; al tocarla se abre
/// a pantalla completa ([ArrivalMapPage]). Sin coordenadas de la sede no se
/// muestra.
///
/// Siempre dice qué recibe Google: con la ubicación, la posición aproximada
/// (unos 100 m); sin ella, solo la sede. Quadrapp nunca la recibe.
class ArrivalMapCard extends StatelessWidget {
  const ArrivalMapCard({super.key});

  static const double _previewHeight = 180;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ArrivalMapCubit, ArrivalMapState>(
      builder: (context, map) {
        if (!map.hasMap) return const SizedBox.shrink();
        final l10n = AppLocalizations.of(context);
        final theme = Theme.of(context);
        final colors = context.qaColors;
        final language = Localizations.localeOf(context).languageCode;
        final label = _semanticLabel(l10n, map);
        return Padding(
          padding: const EdgeInsets.only(top: QaSpacing.lg),
          child: QaCard(
            padding: EdgeInsets.zero,
            onTap: () => _open(context, map),
            semanticLabel: label,
            semanticHint: l10n.map_openHint,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    QaSpacing.lg,
                    QaSpacing.lg,
                    QaSpacing.lg,
                    QaSpacing.md,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.map_outlined, color: colors.primary),
                      const SizedBox(width: QaSpacing.sm),
                      Expanded(
                        child: Text(
                          l10n.map_title,
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      Icon(
                        Icons.open_in_full_rounded,
                        size: 20,
                        color: colors.onSurfaceMuted,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: _previewHeight,
                  child: EmbeddedMap(
                    uri: embeddedMapUri(map, language),
                    semanticLabel: label,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(QaSpacing.lg),
                  child: Text(
                    _note(l10n, map),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _open(BuildContext context, ArrivalMapState map) {
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            fullscreenDialog: true,
            builder: (_) => ArrivalMapPage(map: map),
          ),
        )
        .ignore();
  }
}

String _semanticLabel(AppLocalizations l10n, ArrivalMapState map) {
  final lot = map.lotName ?? '';
  return map.origin == null
      ? l10n.map_semanticsLot(lot)
      : l10n.map_semanticsRoute(lot);
}

String _note(AppLocalizations l10n, ArrivalMapState map) =>
    map.origin == null ? l10n.map_noteLot : l10n.map_noteLocation;

/// El mapa a pantalla completa, para moverlo y acercarlo.
class ArrivalMapPage extends StatelessWidget {
  const ArrivalMapPage({required this.map, super.key});

  final ArrivalMapState map;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;
    final language = Localizations.localeOf(context).languageCode;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            QaTopBar(
              title: map.lotName ?? l10n.map_title,
              onBack: () => Navigator.of(context).pop(),
              backLabel: l10n.common_back,
            ),
            Expanded(
              child: EmbeddedMap(
                uri: embeddedMapUri(map, language),
                semanticLabel: _semanticLabel(l10n, map),
                interactive: true,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(QaSpacing.lg),
              child: Text(
                _note(l10n, map),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

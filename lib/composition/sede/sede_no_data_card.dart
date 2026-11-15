// US04 esc. 2
import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';

/// Una sede sin distribución publicada se presenta sin disponibilidad
/// (US04 esc. 2), con la salida de elegir otra.
class SedeNoDataCard extends StatelessWidget {
  const SedeNoDataCard({
    required this.lotName,
    required this.onPickAnother,
    super.key,
  });

  final String lotName;
  final VoidCallback onPickAnother;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;
    return QaCard(
      padding: const EdgeInsets.all(QaSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(
            child: QaIllustration(kind: QaIllustrationKind.signalLost),
          ),
          const SizedBox(height: QaSpacing.md),
          Semantics(
            header: true,
            child: Text(
              '$lotName · ${l10n.lots_noCurrentData}',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: QaSpacing.xs),
          Text(
            l10n.lots_noCurrentDataHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceMuted,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: QaSpacing.lg),
          QaButton(
            label: l10n.home_pickAnother,
            variant: QaButtonVariant.tonal,
            expand: true,
            onPressed: onPickAnother,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/app/gallery/gallery_parts.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';

/// Profundidad, ilustraciones y movimiento del sistema de diseño: las dos
/// elevaciones, el héroe de marca, el anillo, el punto "Live", las
/// ilustraciones, el skeleton con brillo y las ventanas emergentes.
class GalleryDepth extends StatelessWidget {
  const GalleryDepth({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;

    Widget card(QaElevationLevel level, String text) => QaCard(
      elevation: level,
      child: Text(text, style: theme.textTheme.titleSmall),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GallerySection(
          title: 'QaCard',
          children: [
            card(QaElevationLevel.low, l10n.gallery_cardLow),
            const SizedBox(height: QaSpacing.lg),
            card(QaElevationLevel.high, l10n.gallery_cardHigh),
            const SizedBox(height: QaSpacing.lg),
            QaCard(
              onTap: () {},
              semanticLabel: l10n.gallery_cardTap,
              child: Text(
                l10n.gallery_cardTap,
                style: theme.textTheme.titleSmall,
              ),
            ),
            const SizedBox(height: QaSpacing.lg),
            QaCard(
              hero: true,
              child: Row(
                children: [
                  QaAvailabilityRing(
                    free: 45,
                    occupied: 72,
                    unknown: 3,
                    size: 120,
                    strokeWidth: 12,
                    style: QaRingStyle.onBrand,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        QaCountUp(
                          value: 45,
                          style: theme.textTheme.displaySmall?.copyWith(
                            color: colors.onBrand,
                          ),
                        ),
                        Text(
                          l10n.gallery_heroFree,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onBrand,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: QaSpacing.lg),
                  Expanded(
                    child: Text(
                      l10n.gallery_heroTitle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.onBrand,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        GallerySection(
          title: 'QaAvailabilityRing',
          children: [
            Wrap(
              spacing: QaSpacing.lg,
              runSpacing: QaSpacing.lg,
              children: [
                for (final (free, occupied, unknown) in const [
                  (45, 72, 3),
                  (0, 78, 2),
                  (113, 37, 0),
                  (0, 0, 0),
                ])
                  QaAvailabilityRing(
                    free: free,
                    occupied: occupied,
                    unknown: unknown,
                    size: 96,
                    strokeWidth: 10,
                    child: Text(
                      '$free',
                      style: theme.textTheme.headlineMedium,
                    ),
                  ),
              ],
            ),
          ],
        ),
        GallerySection(
          title: 'QaLiveBadge',
          children: [
            Wrap(
              spacing: QaSpacing.md,
              runSpacing: QaSpacing.md,
              children: [
                QaLiveBadge(
                  status: QaLiveStatus.live,
                  label: l10n.gallery_liveLive,
                ),
                QaLiveBadge(
                  status: QaLiveStatus.reconnecting,
                  label: l10n.gallery_liveReconnecting,
                ),
                QaLiveBadge(
                  status: QaLiveStatus.offline,
                  label: l10n.gallery_liveOffline,
                ),
              ],
            ),
          ],
        ),
        GallerySection(
          title: 'QaIllustration',
          children: [
            Wrap(
              spacing: QaSpacing.md,
              runSpacing: QaSpacing.md,
              children: [
                for (final kind in QaIllustrationKind.values)
                  QaIllustration(kind: kind, height: 96),
              ],
            ),
          ],
        ),
        GallerySection(
          title: 'QaSkeleton',
          children: [
            QaLoadingRegion(
              semanticLabel: l10n.gallery_stateLoading,
              child: const QaCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    QaSkeleton(width: 160, height: 20),
                    SizedBox(height: QaSpacing.lg),
                    QaSkeleton(height: 12),
                    SizedBox(height: QaSpacing.sm),
                    QaSkeleton.line(width: 200),
                  ],
                ),
              ),
            ),
          ],
        ),
        GallerySection(
          title: 'QaBottomSheet · QaConfirmDialog · QaSnackbar',
          children: [
            QaButton(
              label: l10n.gallery_openSheet,
              variant: QaButtonVariant.tonal,
              expand: true,
              onPressed: () => showQaBottomSheet<void>(
                context,
                builder: (context) => QaBottomSheet(
                  title: l10n.gallery_sheetTitle,
                  closeLabel: l10n.gallery_sheetClose,
                  footer: QaButton(
                    label: l10n.gallery_sheetAction,
                    size: QaButtonSize.large,
                    expand: true,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  child: Text(l10n.gallery_sheetBody),
                ),
              ),
            ),
            const SizedBox(height: QaSpacing.sm),
            QaButton(
              label: l10n.gallery_openConfirm,
              variant: QaButtonVariant.tonal,
              expand: true,
              onPressed: () => showQaConfirmDialog(
                context,
                title: l10n.gallery_confirmTitle,
                subject: l10n.gallery_confirmSubject,
                message: l10n.gallery_confirmMessage,
                confirmLabel: l10n.gallery_confirmAction,
                cancelLabel: l10n.signOut_cancel,
                icon: Icons.sensors_outlined,
                destructive: true,
              ),
            ),
            const SizedBox(height: QaSpacing.sm),
            QaButton(
              label: l10n.gallery_openSnack,
              variant: QaButtonVariant.tonal,
              expand: true,
              onPressed: () => showQaSnackbar(
                context,
                message: l10n.gallery_snackMessage,
                undoLabel: l10n.gallery_snackUndo,
                onUndo: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }
}

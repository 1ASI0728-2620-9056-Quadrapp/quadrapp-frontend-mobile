import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/app/gallery/gallery_parts.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';

/// Chip de estado, confianza, antigüedad, avisos, vacío, error y skeleton.
class GalleryStatus extends StatelessWidget {
  const GalleryStatus({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final time = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(const TimeOfDay(hour: 8, minute: 42));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GallerySection(
          title: 'QaStatusChip',
          children: [
            GalleryState(
              label: l10n.gallery_stateSuccess,
              child: Wrap(
                spacing: QaSpacing.sm,
                runSpacing: QaSpacing.sm,
                children: [
                  QaStatusChip(
                    tone: QaTone.free,
                    label: l10n.gallery_statusFree,
                  ),
                  QaStatusChip(
                    tone: QaTone.limited,
                    label: l10n.gallery_statusLimited,
                  ),
                  QaStatusChip(
                    tone: QaTone.occupied,
                    label: l10n.gallery_statusOccupied,
                  ),
                  QaStatusChip(
                    tone: QaTone.unknown,
                    label: l10n.gallery_statusUnknown,
                  ),
                ],
              ),
            ),
          ],
        ),
        GallerySection(
          title: 'QaConfidenceMeter',
          children: [
            GalleryState(
              label: l10n.gallery_stateSuccess,
              child: Wrap(
                spacing: QaSpacing.xl,
                runSpacing: QaSpacing.md,
                children: [
                  QaConfidenceMeter(
                    level: QaConfidenceLevel.high,
                    label: l10n.gallery_confidenceHigh,
                  ),
                  QaConfidenceMeter(
                    level: QaConfidenceLevel.medium,
                    label: l10n.gallery_confidenceMedium,
                  ),
                ],
              ),
            ),
            GalleryState(
              label: l10n.gallery_statePartial,
              child: QaConfidenceMeter(
                level: QaConfidenceLevel.low,
                label: l10n.gallery_confidenceLow,
                note: l10n.gallery_confidenceLowNote,
              ),
            ),
          ],
        ),
        GallerySection(
          title: 'QaFreshnessLabel',
          children: [
            GalleryState(
              label: l10n.gallery_stateSuccess,
              child: QaFreshnessLabel(label: l10n.gallery_freshnessFresh(20)),
            ),
            GalleryState(
              label: l10n.gallery_statePartial,
              child: QaFreshnessLabel(
                label: l10n.gallery_freshnessStale(time),
                isStale: true,
              ),
            ),
          ],
        ),
        GallerySection(
          title: 'QaBanner',
          children: [
            GalleryState(
              label: l10n.gallery_stateError,
              child: QaBanner(
                kind: QaBannerKind.offline,
                message: l10n.gallery_bannerOffline(time),
                actionLabel: l10n.gallery_errorRetry,
                onAction: () {},
              ),
            ),
            GalleryState(
              label: l10n.gallery_statePartial,
              child: QaBanner(
                kind: QaBannerKind.stale,
                message: l10n.gallery_bannerStale(time),
              ),
            ),
            GalleryState(
              label: l10n.gallery_stateError,
              child: QaBanner(
                kind: QaBannerKind.error,
                message: l10n.gallery_bannerError,
              ),
            ),
            GalleryState(
              label: l10n.gallery_stateSuccess,
              child: QaBanner(
                kind: QaBannerKind.info,
                message: l10n.gallery_bannerInfo,
              ),
            ),
          ],
        ),
        GallerySection(
          title: 'QaEmptyState',
          children: [
            GalleryState(
              label: l10n.gallery_stateEmpty,
              child: GallerySurface(
                child: QaEmptyState(
                  icon: Icons.notifications_none,
                  title: l10n.gallery_emptyTitle,
                  message: l10n.gallery_emptyMessage,
                  actionLabel: l10n.gallery_emptyAction,
                  onAction: () {},
                ),
              ),
            ),
          ],
        ),
        GallerySection(
          title: 'QaErrorState',
          children: [
            GalleryState(
              label: l10n.gallery_stateError,
              child: GallerySurface(
                child: QaErrorState(
                  title: l10n.gallery_errorTitle,
                  message: l10n.gallery_errorMessage,
                  retryLabel: l10n.gallery_errorRetry,
                  onRetry: () {},
                ),
              ),
            ),
          ],
        ),
        GallerySection(
          title: 'QaSkeleton',
          children: [
            GalleryState(
              label: l10n.gallery_stateLoading,
              child: QaLoadingRegion(
                semanticLabel: l10n.gallery_stateLoading,
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    QaSkeleton(width: 160, height: 32),
                    SizedBox(height: QaSpacing.sm),
                    QaSkeleton.line(),
                    SizedBox(height: QaSpacing.sm),
                    QaSkeleton.line(width: 200),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

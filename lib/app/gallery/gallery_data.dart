import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/app/gallery/gallery_parts.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';

const int _columns = 6;
const int _rows = 4;

QaSpaceState _initialState(int index) {
  if (index % 7 == 0) return QaSpaceState.unknown;
  return index % 3 == 0 ? QaSpaceState.free : QaSpaceState.occupied;
}

/// Placa de llegada, barras de horizonte, mapa de espacios y KPI, cada uno con
/// sus cinco estados: cargando, vacío, error, parcial/desactualizado y éxito.
class GalleryData extends StatefulWidget {
  const GalleryData({super.key});

  @override
  State<GalleryData> createState() => _GalleryDataState();
}

class _GalleryDataState extends State<GalleryData> {
  late List<QaSpaceCell> _cells = [
    for (var i = 0; i < _columns * _rows; i++)
      QaSpaceCell(
        id: i,
        x: (i % _columns).toDouble(),
        y: (i ~/ _columns).toDouble(),
        state: _initialState(i),
      ),
  ];

  /// Cambia el estado del espacio 3 para ver el pulso de 400 ms.
  void _simulateChange() {
    setState(() {
      _cells = [
        for (final cell in _cells)
          if (cell.id == 3)
            QaSpaceCell(
              id: cell.id,
              x: cell.x,
              y: cell.y,
              state: cell.state == QaSpaceState.free
                  ? QaSpaceState.occupied
                  : QaSpaceState.free,
            )
          else
            cell,
      ];
    });
  }

  ({int free, int occupied, int unknown}) _counts(Iterable<QaSpaceCell> cells) {
    var free = 0;
    var occupied = 0;
    var unknown = 0;
    for (final cell in cells) {
      switch (cell.state) {
        case QaSpaceState.free:
          free++;
        case QaSpaceState.occupied:
          occupied++;
        case QaSpaceState.unknown:
          unknown++;
      }
    }
    return (free: free, occupied: occupied, unknown: unknown);
  }

  QaZoneSummary _zone(
    AppLocalizations l10n,
    String name,
    int fromRow,
    int toRow,
  ) {
    final counts = _counts(_cells.where((c) => c.y >= fromRow && c.y < toRow));
    final zoneName = l10n.gallery_zoneName(name);
    return QaZoneSummary(
      name: zoneName,
      freeText: l10n.gallery_zoneFree(counts.free),
      occupiedText: l10n.gallery_zoneOccupied(counts.occupied),
      unknownText: l10n.gallery_zoneUnknown(counts.unknown),
      semanticLabel: l10n.gallery_zoneSemantic(
        name,
        counts.free,
        counts.occupied,
        counts.unknown,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final time = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(const TimeOfDay(hour: 8, minute: 42));
    final saturation = MaterialLocalizations.of(
      context,
    ).formatTimeOfDay(const TimeOfDay(hour: 9, minute: 20));

    QaHorizonBarData bar(
      int minutes,
      double fraction,
      QaTone tone, {
      QaHorizonBarStatus status = QaHorizonBarStatus.available,
    }) {
      final percent = (fraction * 100).round();
      return QaHorizonBarData(
        label: l10n.gallery_horizonLabel(minutes),
        semanticLabel: switch (status) {
          QaHorizonBarStatus.available => l10n.gallery_horizonSemantic(
            minutes,
            percent,
          ),
          QaHorizonBarStatus.missing => l10n.gallery_horizonMissingSemantic(
            minutes,
          ),
          QaHorizonBarStatus.expired => l10n.gallery_horizonExpiredSemantic(
            minutes,
          ),
        },
        valueLabel: status == QaHorizonBarStatus.available
            ? l10n.gallery_horizonValue(percent)
            : null,
        fraction: fraction,
        tone: tone,
        status: status,
      );
    }

    final counts = _counts(_cells);
    final legend = QaSpaceLegend(
      free: l10n.gallery_statusFree,
      occupied: l10n.gallery_statusOccupied,
      unknown: l10n.gallery_statusUnknown,
    );
    final zones = [_zone(l10n, 'A', 0, 2), _zone(l10n, 'B', 2, 4)];
    final summary = l10n.gallery_mapSummary(
      counts.free,
      counts.occupied,
      counts.unknown,
    );

    Widget emptyBlock() => GallerySurface(
      child: QaEmptyState(
        icon: Icons.inbox_outlined,
        title: l10n.gallery_emptyTitle,
        message: l10n.gallery_emptyMessage,
        compact: true,
      ),
    );
    Widget errorBlock() => GallerySurface(
      child: QaErrorState(
        title: l10n.gallery_errorTitle,
        message: l10n.gallery_errorMessage,
        retryLabel: l10n.gallery_errorRetry,
        onRetry: () {},
        compact: true,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GallerySection(
          title: 'QaArrivalPlate',
          children: [
            GalleryState(
              label: l10n.gallery_stateLoading,
              child: QaArrivalPlate.loading(
                semanticLabel: l10n.gallery_stateLoading,
              ),
            ),
            GalleryState(label: l10n.gallery_stateEmpty, child: emptyBlock()),
            GalleryState(label: l10n.gallery_stateError, child: errorBlock()),
            GalleryState(
              label: l10n.gallery_statePartial,
              child: QaArrivalPlate(
                headline: l10n.gallery_plateHeadline(18),
                categoryLabel: l10n.gallery_plateLimited,
                tone: QaTone.limited,
                detail: l10n.gallery_plateDetail(48),
                note: l10n.gallery_confidenceLowNote,
                footnote: l10n.gallery_plateFootnote(
                  l10n.gallery_confidenceLow,
                  time,
                ),
                isPartial: true,
              ),
            ),
            GalleryState(
              label: l10n.gallery_stateSuccess,
              child: Column(
                children: [
                  QaArrivalPlate(
                    headline: l10n.gallery_plateHeadline(18),
                    categoryLabel: l10n.gallery_plateHigh,
                    tone: QaTone.free,
                    detail: l10n.gallery_plateDetail(82),
                    footnote: l10n.gallery_plateFootnote(
                      l10n.gallery_confidenceMedium,
                      time,
                    ),
                  ),
                  const SizedBox(height: QaSpacing.md),
                  QaArrivalPlate(
                    headline: l10n.gallery_plateHeadline(25),
                    categoryLabel: l10n.gallery_plateLimited,
                    tone: QaTone.limited,
                    detail: l10n.gallery_plateDetail(48),
                    footnote: l10n.gallery_plateFootnote(
                      l10n.gallery_confidenceHigh,
                      time,
                    ),
                  ),
                  const SizedBox(height: QaSpacing.md),
                  QaArrivalPlate(
                    headline: l10n.gallery_plateHeadline(40),
                    categoryLabel: l10n.gallery_plateLow,
                    tone: QaTone.full,
                    detail: l10n.gallery_plateDetail(14),
                    footnote: l10n.gallery_plateFootnote(
                      l10n.gallery_confidenceHigh,
                      time,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        GallerySection(
          title: 'QaHorizonBars',
          children: [
            GalleryState(
              label: l10n.gallery_stateLoading,
              child: QaHorizonBars.loading(
                semanticLabel: l10n.gallery_stateLoading,
              ),
            ),
            GalleryState(label: l10n.gallery_stateEmpty, child: emptyBlock()),
            GalleryState(label: l10n.gallery_stateError, child: errorBlock()),
            GalleryState(
              label: l10n.gallery_statePartial,
              child: QaHorizonBars(
                bars: [
                  bar(15, 0.42, QaTone.free),
                  bar(
                    30,
                    0,
                    QaTone.unknown,
                    status: QaHorizonBarStatus.missing,
                  ),
                  bar(
                    45,
                    0,
                    QaTone.unknown,
                    status: QaHorizonBarStatus.expired,
                  ),
                  bar(60, 0.95, QaTone.full),
                ],
              ),
            ),
            GalleryState(
              label: l10n.gallery_stateSuccess,
              child: QaHorizonBars(
                bars: [
                  bar(15, 0.42, QaTone.free),
                  bar(30, 0.68, QaTone.limited),
                  bar(45, 0.86, QaTone.full),
                  bar(60, 0.95, QaTone.full),
                ],
                saturationLabel: l10n.gallery_horizonSaturation(saturation),
              ),
            ),
          ],
        ),
        GallerySection(
          title: 'QaSpaceMap',
          children: [
            GalleryState(
              label: l10n.gallery_stateLoading,
              child: QaSpaceMap.loading(
                semanticLabel: l10n.gallery_stateLoading,
              ),
            ),
            GalleryState(label: l10n.gallery_stateEmpty, child: emptyBlock()),
            GalleryState(label: l10n.gallery_stateError, child: errorBlock()),
            GalleryState(
              label: l10n.gallery_statePartial,
              child: Column(
                children: [
                  QaBanner(
                    kind: QaBannerKind.stale,
                    message: l10n.gallery_bannerStale(time),
                  ),
                  const SizedBox(height: QaSpacing.md),
                  QaSpaceMap(
                    cells: _cells,
                    zones: const [],
                    summaryLabel: summary,
                    legend: legend,
                    isStale: true,
                  ),
                ],
              ),
            ),
            GalleryState(
              label: l10n.gallery_stateSuccess,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  QaSpaceMap(
                    cells: _cells,
                    zones: zones,
                    summaryLabel: summary,
                    legend: legend,
                  ),
                  const SizedBox(height: QaSpacing.sm),
                  QaButton(
                    label: l10n.gallery_mapSimulate,
                    variant: QaButtonVariant.tonal,
                    onPressed: _simulateChange,
                  ),
                ],
              ),
            ),
          ],
        ),
        GallerySection(
          title: 'QaKpi',
          children: [
            GalleryState(
              label: l10n.gallery_stateLoading,
              child: QaKpi.loading(
                label: l10n.gallery_kpiLabel,
                semanticLabel: l10n.gallery_stateLoading,
              ),
            ),
            GalleryState(
              label: l10n.gallery_stateEmpty,
              child: QaKpi.empty(
                label: l10n.gallery_kpiLabel,
                emptyText: l10n.gallery_kpiEmpty,
              ),
            ),
            GalleryState(
              label: l10n.gallery_stateError,
              child: QaKpi.error(
                label: l10n.gallery_kpiLabel,
                errorText: l10n.gallery_kpiError,
              ),
            ),
            GalleryState(
              label: l10n.gallery_statePartial,
              child: QaKpi(
                label: l10n.gallery_kpiLabel,
                value: '34',
                caption: l10n.gallery_kpiCaption(120),
                staleLabel: l10n.gallery_freshnessStale(time),
              ),
            ),
            GalleryState(
              label: l10n.gallery_stateSuccess,
              child: QaKpi(
                label: l10n.gallery_kpiLabel,
                value: '34',
                caption: l10n.gallery_kpiCaption(120),
                tone: QaTone.free,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

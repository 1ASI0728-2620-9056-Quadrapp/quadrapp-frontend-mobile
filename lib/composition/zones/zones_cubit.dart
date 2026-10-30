// US06, US07, US08
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quadrapp_mobile/composition/zones/zones_state.dart';
import 'package:quadrapp_mobile/contexts/occupancy/occupancy.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

/// Cubit de Zonas: la distribución de la sede elegida (pabellones, niveles y
/// espacios) y su ocupación en vivo. Lo comparten las tres pantallas de Zonas
/// (la sede, el pabellón y el nivel), así que un cambio en tiempo real se ve
/// en la que esté abierta.
///
/// Estados (`ViewState<ZonesOverview>`):
/// - `ViewLoading` (con `previous` al recargar): skeleton o el contenido;
/// - `ViewError`: no se pudo leer **nada** (con `previous` si ya había algo);
/// - `ViewData`: todo llegó (`offline` si los conteos salieron de la caché);
/// - `ViewPartial`: llegó una de las dos partes y se ve lo que hay.
///
/// La sede sin distribución publicada no pide nada y se presenta sin
/// disponibilidad (US04 esc. 2). Los conteos por pabellón y por nivel se
/// recalculan con la distribución en cada cambio de la ocupación; un espacio
/// sin datos nunca cuenta como libre (US08).
class ZonesCubit extends Cubit<ViewState<ZonesOverview>> {
  ZonesCubit({
    required this._getLotLayout,
    required this._getLotOccupancy,
    required this._watchLotFeed,
    required this._getZoneSummary,
    required this._getLevelSummary,
  }) : super(const ViewInitial());

  final GetLotLayout _getLotLayout;
  final GetLotOccupancy _getLotOccupancy;
  final WatchLotFeed _watchLotFeed;
  final GetZoneSummary _getZoneSummary;
  final GetLevelSummary _getLevelSummary;

  ParkingLot? _lot;

  // Se cancela en `_stopWatching` (al cambiar de sede y en `close`).
  // ignore: cancel_subscriptions
  StreamSubscription<OccupancyFeedEvent>? _feed;

  ZonesOverview? get _current => switch (state) {
    ViewData(:final data) => data,
    ViewPartial(:final data) => data,
    ViewLoading(:final previous) => previous,
    ViewError(:final previous) => previous,
    ViewInitial() || ViewEmpty() => null,
  };

  /// Cambió la sede elegida. Una sede nueva carga todo; la misma no hace nada.
  Future<void> setLot(ParkingLot? lot) async {
    if (lot?.id == _lot?.id) return;
    _lot = lot;
    _stopWatching();
    if (lot == null) {
      emit(const ViewInitial());
      return;
    }
    await load();
  }

  /// Carga todo de la sede (primera carga, reintento y deslizar para recargar).
  Future<void> load() async {
    final lot = _lot;
    if (lot == null) return;
    emit(ViewLoading(previous: _current));
    if (!lot.hasPublishedLayout) {
      emit(ViewData(ZonesOverview(lot: lot)));
      return;
    }

    final results = await Future.wait([
      _getLotLayout(lot.id),
      _getLotOccupancy(lot.id),
    ]);
    if (isClosed || _lot?.id != lot.id) return;
    final layoutResult = results[0] as Result<LotLayout>;
    final occupancyResult = results[1] as Result<LotOccupancy>;
    final layout = layoutResult.valueOrNull;
    final occupancy = occupancyResult.valueOrNull;

    if (layout == null && occupancy == null) {
      emit(
        ViewError(
          layoutResult.failureOrNull ??
              occupancyResult.failureOrNull ??
              const UnknownFailure(),
          previous: _current,
        ),
      );
      return;
    }

    _emitOverview(
      _counted(
        ZonesOverview(
          lot: lot,
          layout: layout,
          occupancy: occupancy,
          layoutFailure: layoutResult.failureOrNull,
          occupancyFailure: occupancyResult.failureOrNull,
          link: _current?.link,
        ),
      ),
    );
    if (occupancy != null) _watch(lot);
  }

  Future<void> refresh() => load();

  // ----------------------------------------------------------------- en vivo

  void _watch(ParkingLot lot) {
    _stopWatching();
    if (isClosed) return;
    _feed = _watchLotFeed(lot.id).listen(_onFeed);
  }

  /// Deja de observar. No espera a que termine la limpieza de la conexión:
  /// la sede nueva no debe depender de ella (los avisos ya se detuvieron).
  void _stopWatching() {
    final feed = _feed;
    _feed = null;
    if (feed != null) unawaited(feed.cancel());
  }

  void _onFeed(OccupancyFeedEvent event) {
    switch (event) {
      case LinkChanged(:final link):
        _update((overview) => overview.copyWith(link: link));
      case OccupancyReceived(:final result):
        final occupancy = result.valueOrNull;
        // Un fallo al leer en vivo no tumba lo que ya se ve.
        if (occupancy == null || occupancy.lotId != _lot?.id) return;
        _update(
          (overview) => _counted(overview.copyWith(occupancy: occupancy)),
        );
    }
  }

  // ----------------------------------------------------------------- estado

  /// Recalcula los conteos por pabellón y por nivel con la distribución.
  ZonesOverview _counted(ZonesOverview overview) {
    final layout = overview.layout;
    final occupancy = overview.occupancy;
    if (layout == null || occupancy == null) return overview;
    return overview.copyWith(
      zoneCounts: {
        for (final zone in _getZoneSummary(
          GetZoneSummaryParams(
            occupancy: occupancy,
            membership: layout.membership,
          ),
        ))
          zone.zoneId: zone,
      },
      levelCounts: {
        for (final level in _getLevelSummary(
          GetLevelSummaryParams(
            occupancy: occupancy,
            membership: layout.levelMembership,
          ),
        ))
          level.levelId: level,
      },
    );
  }

  void _emitOverview(ZonesOverview overview) {
    emit(
      overview.isPartial
          ? ViewPartial(overview, missing: _missing(overview))
          : ViewData(overview, offline: overview.isOffline),
    );
  }

  Set<String> _missing(ZonesOverview overview) => {
    if (overview.layout == null) 'layout',
    if (overview.occupancy == null) 'occupancy',
  };

  /// Aplica [change] al contenido actual; si no hay contenido que mostrar, lo
  /// ignora (la próxima carga trae lo último).
  void _update(ZonesOverview Function(ZonesOverview current) change) {
    final current = switch (state) {
      ViewData(:final data) => data,
      ViewPartial(:final data) => data,
      _ => null,
    };
    if (current == null || isClosed) return;
    _emitOverview(change(current));
  }

  @override
  Future<void> close() {
    _stopWatching();
    return super.close();
  }
}

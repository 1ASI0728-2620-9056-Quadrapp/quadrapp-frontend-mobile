// US05, US07, US09 a US15, US36
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quadrapp_mobile/composition/arrival/arrival_state.dart';
import 'package:quadrapp_mobile/composition/arrival/load_horizon_advices.dart';
import 'package:quadrapp_mobile/contexts/occupancy/occupancy.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/prediction_advisory.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

/// Cubit de Inicio («Tu llegada»): la sede elegida, su ocupación en vivo, la
/// asesoría para el tiempo de llegada y cómo puede cambiar a 15, 30, 45 y 60
/// minutos.
///
/// Estados (`ViewState<ArrivalOverview>`):
/// - `ViewLoading` (con `previous` al recargar): skeleton o el contenido;
/// - `ViewError`: no se pudo leer **nada** (con `previous` si ya había algo);
/// - `ViewData`: todo llegó (`offline` si la ocupación salió de la caché);
/// - `ViewPartial`: llegó parte (por ejemplo, la ocupación pero no la
///   asesoría, o faltan horizontes): lo que hay se ve y avisa lo que falta.
///
/// Cada parte se pide por separado y falla por separado. La sede sin
/// distribución publicada no pide nada y se presenta sin disponibilidad
/// (US04 esc. 2). Lo único que viaja al servidor para la asesoría es el
/// estacionamiento y los minutos (TS08).
///
/// Solo la ocupación de la sede se observa en tiempo real (US07): cada cambio
/// la reemplaza y el estado de la conexión es el real, nunca decorativo.
class ArrivalCubit extends Cubit<ViewState<ArrivalOverview>> {
  ArrivalCubit({
    required this._getLotOccupancy,
    required this._requestArrivalAdvice,
    required this._recalculateAdvice,
    required this._getNextAvailability,
    required this._watchLotFeed,
    required this._clock,
  }) : super(const ViewInitial());

  final GetLotOccupancy _getLotOccupancy;
  final RequestArrivalAdvice _requestArrivalAdvice;
  final RecalculateArrivalAdvice _recalculateAdvice;
  final GetNextAvailability _getNextAvailability;
  final WatchLotFeed _watchLotFeed;
  final Clock _clock;

  ParkingLot? _lot;
  int? _eta;

  /// Llegó un ETA nuevo mientras se cargaba: la carga ya había leído el
  /// anterior, así que al terminar se vuelve a pedir la asesoría.
  bool _etaChangedWhileLoading = false;

  // Se cancela en `_stopWatching` (al cambiar de sede y en `close`).
  // ignore: cancel_subscriptions
  StreamSubscription<OccupancyFeedEvent>? _feed;

  ArrivalOverview? get _current => switch (state) {
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

  /// Cambió el tiempo de llegada (lo manual o la estimación en el
  /// dispositivo): vuelve a pedir **solo** la asesoría, sin tocar lo demás.
  Future<void> setEta(int? minutes) async {
    if (minutes == _eta) return;
    _eta = minutes;
    if (state is ViewLoading) {
      _etaChangedWhileLoading = true;
      return;
    }
    await _refreshAdvice();
  }

  Future<void> _refreshAdvice() async {
    final current = _current;
    final lot = _lot;
    if (current == null || lot == null || current.hasNoData) return;
    final (status, advice) = await _loadAdvice(lot, current.advice);
    if (isClosed || _lot?.id != lot.id) return;
    final change = _changeBetween(current.advice, advice);
    _update(
      (overview) => overview.copyWith(
        advice: advice,
        clearAdvice: advice == null,
        adviceStatus: status,
        lastChange: change,
      ),
    );
  }

  /// Qué cambió entre la asesoría de antes y la nueva, si cambió el tiempo de
  /// llegada (US14); `null` si no hay con qué comparar o la asesoría se
  /// conservó (el ETA cambió menos de 2 minutos).
  AdviceChange? _changeBetween(ArrivalAdvice? before, ArrivalAdvice? after) {
    if (before == null ||
        after == null ||
        !before.isAvailable ||
        !after.isAvailable ||
        before.etaMinutes == after.etaMinutes) {
      return null;
    }
    return AdviceChange(
      previousEta: before.etaMinutes.value,
      eta: after.etaMinutes.value,
      previousProbability: before.probabilityOfSpace,
      probability: after.probabilityOfSpace,
      previousCategory: before.category,
      category: after.category,
      at: _clock.monotonic(),
    );
  }

  /// Carga todo de la sede (primera carga, reintento y deslizar para recargar).
  Future<void> load() async {
    final lot = _lot;
    if (lot == null) return;
    final eta = _eta;
    _etaChangedWhileLoading = false;
    emit(ViewLoading(previous: _current));
    if (!lot.hasPublishedLayout) {
      emit(ViewData(ArrivalOverview(lot: lot)));
      return;
    }

    final results = await Future.wait([
      _getLotOccupancy(lot.id),
      _loadAdvice(lot, null),
      _loadHorizons(lot),
    ]);
    if (isClosed || _lot?.id != lot.id) return;
    final occupancyResult = results[0] as Result<LotOccupancy>;
    final (adviceStatus, advice) = results[1] as (AdviceStatus, ArrivalAdvice?);
    final horizons = results[2] as List<HorizonAdvice>;

    final occupancy = occupancyResult.valueOrNull;
    final nothingLoaded =
        occupancy == null &&
        (eta == null || advice == null) &&
        horizons.every((h) => !h.isAvailable);
    if (nothingLoaded) {
      emit(
        ViewError(
          occupancyResult.failureOrNull ?? const UnknownFailure(),
          previous: _current,
        ),
      );
      return;
    }

    var overview = ArrivalOverview(
      lot: lot,
      occupancy: occupancy,
      occupancyFailure: occupancyResult.failureOrNull,
      advice: advice,
      adviceStatus: adviceStatus,
      horizons: horizons,
      link: _current?.link,
    );
    overview = await _withNextAvailability(overview);
    if (isClosed || _lot?.id != lot.id) return;
    _emitOverview(overview);
    if (occupancy != null) _watch(lot);
    if (_etaChangedWhileLoading) {
      _etaChangedWhileLoading = false;
      await _refreshAdvice();
    }
  }

  Future<void> refresh() => load();

  // ------------------------------------------------------------------ partes

  /// La asesoría para el ETA vigente. Sin ETA, hay que elegirlo; si falla o
  /// llega sin categoría, no está disponible.
  Future<(AdviceStatus, ArrivalAdvice?)> _loadAdvice(
    ParkingLot lot,
    ArrivalAdvice? current,
  ) async {
    final eta = _eta;
    if (eta == null) return (AdviceStatus.needsEta, null);
    final result = await _recalculateAdvice(
      RecalculateArrivalAdviceParams(
        lotId: lot.id,
        newEtaMinutes: eta,
        current: current,
      ),
    );
    final advice = result.valueOrNull;
    if (advice == null) return (AdviceStatus.unavailable, null);
    return (
      advice.isAvailable ? AdviceStatus.available : AdviceStatus.unavailable,
      advice,
    );
  }

  /// La asesoría de cada horizonte (también la usa Predicción).
  Future<List<HorizonAdvice>> _loadHorizons(ParkingLot lot) =>
      loadHorizonAdvices(_requestArrivalAdvice, lot.id);

  /// Si la sede está llena, cuándo se libera un espacio (US36); si hay libres,
  /// no se pide nada.
  Future<ArrivalOverview> _withNextAvailability(
    ArrivalOverview overview,
  ) async {
    final occupancy = overview.occupancy;
    if (occupancy == null || occupancy.free > 0) {
      return overview.copyWith(clearNextAvailability: true);
    }
    final result = await _getNextAvailability(
      GetNextAvailabilityParams(lotId: overview.lot.id, hasFreeSpaces: false),
    );
    final next = result.valueOrNull;
    return next == null
        ? overview.copyWith(clearNextAvailability: true)
        : overview.copyWith(nextAvailability: next);
  }

  // ----------------------------------------------------------------- en vivo

  void _watch(ParkingLot lot) {
    _stopWatching();
    if (isClosed) return;
    _feed = _watchLotFeed(lot.id).listen((event) => unawaited(_onFeed(event)));
  }

  /// Deja de observar. No espera a que termine la limpieza de la conexión:
  /// la sede nueva no debe depender de ella (los avisos ya se detuvieron).
  void _stopWatching() {
    final feed = _feed;
    _feed = null;
    if (feed != null) unawaited(feed.cancel());
  }

  Future<void> _onFeed(OccupancyFeedEvent event) async {
    switch (event) {
      case LinkChanged(:final link):
        _update((overview) => overview.copyWith(link: link));
      case OccupancyReceived(:final result):
        final occupancy = result.valueOrNull;
        // Un fallo al leer en vivo no tumba lo que ya se ve.
        if (occupancy == null || occupancy.lotId != _lot?.id) return;
        final before = _current?.occupancy?.free ?? 1;
        _update((overview) => overview.copyWith(occupancy: occupancy));
        final becameFull = occupancy.free == 0 && before > 0;
        final stoppedBeingFull = occupancy.free > 0 && before == 0;
        if (becameFull || stoppedBeingFull) {
          final overview = _current;
          if (overview == null) return;
          final updated = await _withNextAvailability(overview);
          if (isClosed) return;
          _update((_) => updated);
        }
    }
  }

  // ----------------------------------------------------------------- estado

  void _emitOverview(ArrivalOverview overview) {
    emit(
      overview.isPartial
          ? ViewPartial(overview, missing: _missing(overview))
          : ViewData(overview, offline: overview.isOffline),
    );
  }

  Set<String> _missing(ArrivalOverview overview) => {
    if (overview.occupancy == null) 'occupancy',
    if (overview.adviceStatus == AdviceStatus.unavailable) 'advice',
    if (overview.horizons.any((h) => !h.isAvailable)) 'horizons',
  };

  /// Aplica [change] al contenido actual; si no hay contenido que mostrar, lo
  /// ignora (la próxima carga trae lo último).
  void _update(ArrivalOverview Function(ArrivalOverview current) change) {
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

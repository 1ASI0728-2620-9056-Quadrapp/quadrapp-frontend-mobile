// US21, US22, US34, TS11
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quadrapp_mobile/composition/analytics/analytics_overview.dart';
import 'package:quadrapp_mobile/contexts/analytics/analytics.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/prediction_advisory.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/time/app_time_formatter.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

/// Cubit de Analítica y precisión (`/ops/analytics`).
///
/// Pide en paralelo el historial de ocupación, las horas pico, la precisión
/// del pronóstico y, en «Hoy» sin filtro de zona, el pronóstico de la próxima
/// hora. Estados (`ViewState<AnalyticsOverview>`):
/// - `ViewLoading` (con `previous` al cambiar el periodo o la zona);
/// - `ViewError`: no llegó **nada**, o el servidor negó el acceso (403); con
///   `previous` si ya había algo;
/// - `ViewPartial`: faltó alguna parte (`missing` con sus nombres);
/// - `ViewData`: llegó todo (un periodo sin registros también: la pantalla
///   lo dice, US21 esc. 3).
class AnalyticsCubit extends Cubit<ViewState<AnalyticsOverview>> {
  AnalyticsCubit({
    required this._getOccupancyHistory,
    required this._getPeakHours,
    required this._getForecastAccuracy,
    required this._getLotForecasts,
    required this._exportReport,
    required this._clock,
  }) : super(const ViewInitial());

  final GetOccupancyHistory _getOccupancyHistory;
  final GetPeakHours _getPeakHours;
  final GetForecastAccuracy _getForecastAccuracy;
  final GetLotForecasts _getLotForecasts;
  final ExportAnalyticsReport _exportReport;
  final Clock _clock;

  LotId? _lotId;
  ZoneId? _zoneId;
  AnalyticsPeriod _period = AnalyticsPeriod.last30Days;

  /// Si cambia algo a mitad de una carga, la respuesta vieja se descarta.
  int _request = 0;

  /// El periodo elegido (el diseño abre en 30 días).
  AnalyticsPeriod get period => _period;

  /// La zona elegida; `null` es todo el estacionamiento.
  ZoneId? get zoneId => _zoneId;

  AnalyticsOverview? get _current => switch (state) {
    ViewData(:final data) => data,
    ViewPartial(:final data) => data,
    ViewLoading(:final previous) => previous,
    ViewError(:final previous) => previous,
    _ => null,
  };

  /// El rango de [period] que termina ahora, por días de Lima.
  AnalyticsRange rangeOf(AnalyticsPeriod period) => AnalyticsRange.forPeriod(
    period,
    now: _clock.now(),
    utcOffset: AppTimeFormatter.limaOffset,
  );

  /// Carga [lotId]. Otro estacionamiento quita el filtro de zona (sus zonas
  /// son otras) y no conserva lo anterior.
  Future<void> load(LotId lotId) {
    final sameLot = _lotId == lotId;
    _lotId = lotId;
    if (!sameLot) _zoneId = null;
    return _fetchAll(previous: sameLot ? _current : null);
  }

  /// Cambia el periodo (US21 esc. 1): todo se vuelve a pedir.
  Future<void> selectPeriod(AnalyticsPeriod period) async {
    if (period == _period) return;
    _period = period;
    await _fetchAll(previous: _current);
  }

  /// Filtra la ocupación por zona (US21 esc. 2); `null` es todo el
  /// estacionamiento. Las horas pico y la precisión son del estacionamiento y
  /// no cambian.
  Future<void> selectZone(ZoneId? zoneId) async {
    if (zoneId == _zoneId) return;
    _zoneId = zoneId;
    final current = _current;
    final lotId = _lotId;
    if (lotId == null) return;
    if (current == null || current.period != _period) {
      return _fetchAll(previous: current);
    }
    final request = ++_request;
    final loading = current.copyWith(zoneId: zoneId, clearZone: zoneId == null);
    emit(ViewLoading(previous: loading));
    final needsForecast = loading.showsForecast && current.forecasts == null;
    final results = await Future.wait<Result<Object>>([
      _getOccupancyHistory((
        lotId: lotId,
        range: current.range,
        zoneId: zoneId,
      )),
      if (needsForecast) _getLotForecasts(lotId),
    ]);
    if (isClosed || request != _request) return;
    final failures = Map.of(current.failures)
      ..remove(AnalyticsSection.occupancy);
    final history = _take(results[0], AnalyticsSection.occupancy, failures);
    final forecasts = needsForecast
        ? _take(results[1], AnalyticsSection.forecast, failures)
        : current.forecasts;
    _emit(
      AnalyticsOverview(
        lotId: lotId,
        period: current.period,
        range: current.range,
        zoneId: zoneId,
        history: history as OccupancyHistory?,
        peaks: current.peaks,
        accuracy: current.accuracy,
        forecasts: forecasts as LotForecasts?,
        failures: failures,
      ),
      previous: current,
    );
  }

  /// Vuelve a pedir todo, mostrando lo que ya hay.
  Future<void> refresh() => _fetchAll(previous: _current);

  /// Pide el reporte del estacionamiento actual (lo genera el servidor y lo
  /// envía al correo institucional).
  Future<Result<ReportDelivery>> exportReport({
    required AnalyticsRange range,
    required Set<ReportSection> sections,
    required ReportFormat format,
  }) async {
    final lotId = _lotId;
    if (lotId == null) return const Err(UnknownFailure());
    final request = ReportRequest.create(
      lotId: lotId,
      range: range,
      sections: sections,
      format: format,
    );
    return switch (request) {
      Err(:final failure) => Err(failure),
      Success(:final value) => _exportReport(value),
    };
  }

  Future<void> _fetchAll({AnalyticsOverview? previous}) async {
    final lotId = _lotId;
    if (lotId == null) return;
    final request = ++_request;
    final period = _period;
    final zoneId = _zoneId;
    final range = rangeOf(period);
    emit(ViewLoading(previous: previous));

    final withForecast = period == AnalyticsPeriod.today && zoneId == null;
    final query = (lotId: lotId, range: range);
    final results = await Future.wait<Result<Object>>([
      _getOccupancyHistory((lotId: lotId, range: range, zoneId: zoneId)),
      _getPeakHours(query),
      _getForecastAccuracy(query),
      if (withForecast) _getLotForecasts(lotId),
    ]);
    if (isClosed || request != _request) return;

    final failures = <AnalyticsSection, Failure>{};
    final overview = AnalyticsOverview(
      lotId: lotId,
      period: period,
      range: range,
      zoneId: zoneId,
      history:
          _take(results[0], AnalyticsSection.occupancy, failures)
              as OccupancyHistory?,
      peaks: _take(results[1], AnalyticsSection.peaks, failures) as PeakHours?,
      accuracy:
          _take(results[2], AnalyticsSection.accuracy, failures)
              as ForecastAccuracy?,
      forecasts: withForecast
          ? _take(results[3], AnalyticsSection.forecast, failures)
                as LotForecasts?
          : null,
      failures: failures,
    );
    _emit(overview, previous: previous);
  }

  static Object? _take(
    Result<Object> result,
    AnalyticsSection section,
    Map<AnalyticsSection, Failure> failures,
  ) {
    switch (result) {
      case Success(:final value):
        return value;
      case Err(:final failure):
        failures[section] = failure;
        return null;
    }
  }

  void _emit(AnalyticsOverview overview, {AnalyticsOverview? previous}) {
    final failures = overview.failures;
    // El 403 vale para todo: no se muestra nada a medias.
    final forbidden = failures.values.whereType<ForbiddenFailure>().firstOrNull;
    final nothing =
        overview.history == null &&
        overview.peaks == null &&
        overview.accuracy == null;
    if (forbidden != null) {
      emit(ViewError(forbidden, previous: previous));
    } else if (nothing && failures.isNotEmpty) {
      emit(ViewError(failures.values.first, previous: previous));
    } else if (overview.isPartial) {
      emit(ViewPartial(overview, missing: overview.missing));
    } else {
      emit(ViewData(overview));
    }
  }
}

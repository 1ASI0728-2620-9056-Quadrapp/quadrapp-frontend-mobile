// US09, US10, US11, US12, US15
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quadrapp_mobile/composition/arrival/arrival_state.dart';
import 'package:quadrapp_mobile/composition/arrival/load_horizon_advices.dart';
import 'package:quadrapp_mobile/composition/forecast/forecast_state.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/prediction_advisory.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

/// Cubit de Predicción: los pronósticos de la sede elegida a 15, 30, 45 y 60
/// minutos y la asesoría de llegada a cada hora.
///
/// Estados (`ViewState<ForecastOverview>`):
/// - `ViewLoading` (con `previous` al recargar): skeleton o el contenido;
/// - `ViewError`: no se pudo leer **nada** (con `previous` si ya había algo);
/// - `ViewData`: todo llegó, incluida una sede sin pronósticos (la pantalla
///   decide si es un estado vacío);
/// - `ViewPartial`: llegó una parte (por ejemplo, la asesoría sin el detalle
///   de los pronósticos).
///
/// Un horizonte faltante o vencido no es un fallo: lo resuelve
/// `ForecastOverview.rows` con el reloj, porque el vencimiento ocurre mientras
/// la pantalla está abierta. La sede sin distribución publicada no pide nada
/// (US04 esc. 2). Lo único que viaja al servidor es el estacionamiento y los
/// minutos de cada horizonte (TS08).
class ForecastCubit extends Cubit<ViewState<ForecastOverview>> {
  ForecastCubit({
    required this._getLotForecasts,
    required this._requestArrivalAdvice,
  }) : super(const ViewInitial());

  final GetLotForecasts _getLotForecasts;
  final RequestArrivalAdvice _requestArrivalAdvice;

  ParkingLot? _lot;

  ForecastOverview? get _current => switch (state) {
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
      emit(ViewData(ForecastOverview(lot: lot)));
      return;
    }

    final results = await Future.wait([
      _getLotForecasts(lot.id),
      loadHorizonAdvices(_requestArrivalAdvice, lot.id),
    ]);
    if (isClosed || _lot?.id != lot.id) return;
    final forecastsResult = results[0] as Result<LotForecasts>;
    final advices = results[1] as List<HorizonAdvice>;
    final forecasts = forecastsResult.valueOrNull;

    if (forecasts == null && advices.every((a) => !a.isAvailable)) {
      emit(
        ViewError(
          forecastsResult.failureOrNull ?? const UnknownFailure(),
          previous: _current,
        ),
      );
      return;
    }

    final overview = ForecastOverview(
      lot: lot,
      forecasts: forecasts,
      advices: advices,
      forecastsFailure: forecastsResult.failureOrNull,
    );
    emit(
      forecasts == null
          ? ViewPartial(overview, missing: const {'forecasts'})
          : ViewData(overview),
    );
  }

  Future<void> refresh() => load();
}

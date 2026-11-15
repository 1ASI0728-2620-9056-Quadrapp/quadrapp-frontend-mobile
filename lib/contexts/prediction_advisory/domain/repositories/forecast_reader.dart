import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/entities/forecast.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/forecast_horizon.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// Lectura del pronóstico de un estacionamiento a un horizonte (US09, US10).
// ignore: one_member_abstracts
abstract interface class ForecastReader {
  /// `NotFoundFailure` si no hay pronóstico para ese horizonte (el horizonte
  /// "falta", US10 esc. 2).
  Future<Result<Forecast>> read(LotId lotId, ForecastHorizon horizon);
}

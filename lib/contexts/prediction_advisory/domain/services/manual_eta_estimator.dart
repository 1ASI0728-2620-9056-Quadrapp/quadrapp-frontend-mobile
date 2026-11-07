import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/entities/eta_estimate.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/services/eta_estimator.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/value_objects/eta_minutes.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// ETA manual: el conductor elige "llego en 10 / 20 / 30 min" (u otro valor).
/// Siempre está disponible, sin permisos.
class ManualEtaEstimator implements EtaEstimator {
  const ManualEtaEstimator();

  @override
  Future<Result<EtaEstimate?>> estimate(EtaEstimationContext context) async {
    final minutes = context.manualMinutes;
    if (minutes == null) return const Success(null);
    return EtaMinutes.create(
      minutes,
    ).map<EtaEstimate?>(
      (eta) => EtaEstimate(minutes: eta, source: EtaSource.manual),
    );
  }
}

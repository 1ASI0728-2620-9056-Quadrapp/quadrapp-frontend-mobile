import 'package:quadrapp_mobile/contexts/parking_sensing/domain/entities/problem_report.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// Envía un reporte de problema a soporte (`POST /device-incidents`). Ambos
/// roles de Operación reportan; un conductor recibe `ForbiddenFailure`.
// ignore: one_member_abstracts
abstract interface class ProblemReporter {
  Future<Result<ProblemReceipt>> report(ProblemReport report);
}

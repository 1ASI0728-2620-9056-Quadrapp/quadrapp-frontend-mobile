// US20
import 'package:quadrapp_mobile/contexts/parking_sensing/domain/entities/problem_report.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/domain/repositories/problem_reporter.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

/// Reporta a soporte un problema con los dispositivos del estacionamiento.
class ReportDeviceProblem implements UseCase<ProblemReceipt, ProblemReport> {
  const ReportDeviceProblem(this._reporter);

  final ProblemReporter _reporter;

  @override
  Future<Result<ProblemReceipt>> call(ProblemReport report) =>
      _reporter.report(report);
}

import 'package:quadrapp_mobile/contexts/parking_sensing/domain/entities/problem_report.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/domain/repositories/problem_reporter.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/infrastructure/datasources/problem_report_datasource.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/infrastructure/dto/problem_report_dto.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/network/failure_mapper.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// Envía el reporte y traduce la categoría al contrato.
class ProblemReporterImpl implements ProblemReporter {
  const ProblemReporterImpl(this._remote);

  final ProblemReportRemoteDataSource _remote;

  static String categoryToApi(ProblemCategory category) => switch (category) {
    ProblemCategory.noCommunication => 'NO_COMMUNICATION',
    ProblemCategory.wrongData => 'WRONG_DATA',
    ProblemCategory.lowBattery => 'LOW_BATTERY',
    ProblemCategory.other => 'OTHER',
  };

  @override
  Future<Result<ProblemReceipt>> report(ProblemReport report) =>
      guardResult(() async {
        final dto = await _remote.report(
          ProblemReportRequestDto(
            lotId: report.lotId.value,
            category: categoryToApi(report.category),
            deviceId: report.deviceId?.value,
            detail: report.detail,
          ),
        );
        return ProblemReceipt(
          id: DeviceIncidentId(dto.id),
          reportedAt: dto.detectedAt.toUtc(),
        );
      });
}

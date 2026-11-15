// US21, US22, US34
import 'package:quadrapp_mobile/contexts/analytics/domain/entities/analytics_report.dart';
import 'package:quadrapp_mobile/contexts/analytics/domain/repositories/report_exporter.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

/// Pide el reporte de analítica: el servidor lo genera y lo envía al correo
/// institucional de quien lo pide.
class ExportAnalyticsReport implements UseCase<ReportDelivery, ReportRequest> {
  const ExportAnalyticsReport(this._exporter);

  final ReportExporter _exporter;

  @override
  Future<Result<ReportDelivery>> call(ReportRequest request) =>
      _exporter.export(request);
}

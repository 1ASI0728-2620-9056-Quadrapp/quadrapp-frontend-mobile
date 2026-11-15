import 'package:quadrapp_mobile/contexts/analytics/domain/entities/analytics_report.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// Pide al servidor un reporte de analítica (`POST /analytics/reports`).
// ignore: one_member_abstracts
abstract interface class ReportExporter {
  /// `ReportDelivery` si el servidor lo aceptó (202); `ForbiddenFailure` a un
  /// conductor y `ValidationFailure` a una solicitud inválida.
  Future<Result<ReportDelivery>> export(ReportRequest request);
}

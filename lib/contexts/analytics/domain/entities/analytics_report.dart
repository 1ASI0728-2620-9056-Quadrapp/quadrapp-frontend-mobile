import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/analytics/domain/value_objects/analytics_period.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// Lo que puede incluir un reporte exportado.
enum ReportSection {
  /// Ocupación histórica, horas pico y pronóstico (US21, US22).
  occupancy,

  /// Precisión del pronóstico (US34).
  accuracy,

  /// Alertas del periodo.
  alerts,
}

/// El formato del archivo.
enum ReportFormat { pdf, csv }

/// La solicitud de un reporte de analítica. El servidor lo genera y lo envía
/// al correo institucional de quien lo pide: el teléfono no guarda archivos.
class ReportRequest extends Equatable {
  const ReportRequest._({
    required this.lotId,
    required this.range,
    required this.sections,
    required this.format,
  });

  /// La solicitud, o `ValidationFailure` si no tiene contenido.
  static Result<ReportRequest> create({
    required LotId lotId,
    required AnalyticsRange range,
    required Set<ReportSection> sections,
    required ReportFormat format,
  }) {
    if (sections.isEmpty) {
      return const Err(
        ValidationFailure('El reporte no tiene contenido.', {
          'sections': ['empty'],
        }),
      );
    }
    return Success(
      ReportRequest._(
        lotId: lotId,
        range: range,
        sections: Set.unmodifiable(sections),
        format: format,
      ),
    );
  }

  final LotId lotId;
  final AnalyticsRange range;
  final Set<ReportSection> sections;
  final ReportFormat format;

  @override
  List<Object?> get props => [lotId.value, range, sections, format];
}

/// El reporte quedó en camino: a qué correo se envía (enmascarado por el
/// servidor).
class ReportDelivery extends Equatable {
  const ReportDelivery({required this.sentTo});

  final String sentTo;

  @override
  List<Object?> get props => [sentTo];
}

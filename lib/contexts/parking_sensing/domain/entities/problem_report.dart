import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// El tipo de problema que se reporta (docs/06
/// `device_incidents.category`).
enum ProblemCategory { noCommunication, wrongData, lowBattery, other }

/// Un problema con los dispositivos que la universidad reporta a soporte de
/// la plataforma: una incidencia más de la bitácora (`USER_REPORT`, docs/06).
/// La universidad no repara ni da de baja: lo atiende la plataforma.
class ProblemReport extends Equatable {
  const ProblemReport._({
    required this.lotId,
    required this.category,
    this.deviceId,
    this.detail,
  });

  /// Lo que cabe en la descripción.
  static const int maxDetailLength = 1000;

  /// El reporte, o `ValidationFailure` si la descripción es demasiado
  /// larga. Una descripción vacía no se envía.
  static Result<ProblemReport> create({
    required LotId lotId,
    required ProblemCategory category,
    DeviceId? deviceId,
    String? detail,
  }) {
    final text = detail?.trim() ?? '';
    if (text.length > maxDetailLength) {
      return const Err(
        ValidationFailure('La descripción es demasiado larga.', {
          'detail': ['tooLong'],
        }),
      );
    }
    return Success(
      ProblemReport._(
        lotId: lotId,
        category: category,
        deviceId: deviceId,
        detail: text.isEmpty ? null : text,
      ),
    );
  }

  final LotId lotId;
  final ProblemCategory category;

  /// El dispositivo relacionado; `null` si es un problema general del
  /// estacionamiento.
  final DeviceId? deviceId;
  final String? detail;

  @override
  List<Object?> get props => [lotId.value, category, deviceId?.value, detail];
}

/// El reporte quedó registrado.
class ProblemReceipt extends Equatable {
  const ProblemReceipt({required this.id, required this.reportedAt});

  final DeviceIncidentId id;
  final DateTime reportedAt;

  @override
  List<Object?> get props => [id.value, reportedAt];
}

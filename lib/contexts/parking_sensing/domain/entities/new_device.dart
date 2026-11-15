import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/domain/value_objects/device_type.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// Un dispositivo por registrar (US32 esc. 1), ya validado.
///
/// Reglas (docs/06 y docs/07): el identificador físico no está vacío y mide
/// hasta 80 caracteres; el intervalo de reporte es mayor que cero; y la
/// direccionalidad es **obligatoria en un sensor de paso** (docs/06 lo exige
/// con un `CHECK`) y no se envía en los demás tipos.
class NewDevice extends Equatable {
  const NewDevice._({
    required this.lotId,
    required this.type,
    required this.hardwareId,
    required this.expectedReportInterval,
    required this.directional,
  });

  /// Longitud máxima del identificador físico (`devices.hardware_id`).
  static const int maxHardwareIdLength = 80;

  /// Valida los datos del formulario. En caso de error devuelve una
  /// `ValidationFailure` con los campos inválidos (`hardwareId`,
  /// `expectedReportIntervalSec`, `directional`), igual que un 400 del
  /// servidor.
  static Result<NewDevice> create({
    required LotId lotId,
    required DeviceType type,
    required String hardwareId,
    required int? expectedReportIntervalSec,
    bool? directional,
  }) {
    final errors = <String, List<String>>{};
    final id = hardwareId.trim();
    if (id.isEmpty) {
      errors['hardwareId'] = ['required'];
    } else if (id.length > maxHardwareIdLength) {
      errors['hardwareId'] = ['too-long'];
    }
    if (expectedReportIntervalSec == null || expectedReportIntervalSec <= 0) {
      errors['expectedReportIntervalSec'] = ['positive'];
    }
    if (type == DeviceType.passSensor && directional == null) {
      errors['directional'] = ['required'];
    } else if (type != DeviceType.passSensor && directional != null) {
      errors['directional'] = ['not-allowed'];
    }
    if (errors.isNotEmpty) return Err(ValidationFailure(null, errors));
    return Success(
      NewDevice._(
        lotId: lotId,
        type: type,
        hardwareId: id,
        expectedReportInterval: Duration(seconds: expectedReportIntervalSec!),
        directional: directional,
      ),
    );
  }

  final LotId lotId;
  final DeviceType type;
  final String hardwareId;
  final Duration expectedReportInterval;

  /// Solo con `PASS_SENSOR`.
  final bool? directional;

  /// Registrar un sensor (de espacio o de paso) no lo asocia a un espacio ni
  /// a un acceso: eso se hace desde la consola web (US18, US19), y la app lo
  /// avisa.
  bool get needsAssignment => type != DeviceType.gateway;

  @override
  List<Object?> get props => [
    lotId.value,
    type,
    hardwareId,
    expectedReportInterval,
    directional,
  ];
}

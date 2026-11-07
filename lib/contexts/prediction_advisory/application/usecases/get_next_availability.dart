// US36, TS07
import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/entities/next_availability.dart';
import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/repositories/next_availability_reader.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

/// Parámetros de [GetNextAvailability].
class GetNextAvailabilityParams extends Equatable {
  const GetNextAvailabilityParams({
    required this.lotId,
    required this.hasFreeSpaces,
  });

  final LotId lotId;

  /// ¿El estacionamiento tiene espacios libres ahora? Lo informa la pantalla
  /// con la ocupación (un simple booleano: este contexto no conoce a
  /// `occupancy`). Los espacios desconocidos no cuentan como libres.
  final bool hasFreeSpaces;

  @override
  List<Object?> get props => [lotId.value, hasFreeSpaces];
}

/// El tiempo hasta la próxima liberación. **Solo se consulta cuando no hay
/// espacios libres**: con libres no se llama al servidor y no se presenta la
/// estimación (US36 esc. 3). Si el servidor dice que hay libres (carrera con la
/// ocupación), tampoco se presenta.
class GetNextAvailability
    implements UseCase<NextAvailability, GetNextAvailabilityParams> {
  const GetNextAvailability(this._reader);

  final NextAvailabilityReader _reader;

  @override
  Future<Result<NextAvailability>> call(
    GetNextAvailabilityParams params,
  ) async {
    if (params.hasFreeSpaces) {
      return const Success(NextAvailabilityNotApplicable());
    }
    return _reader.read(params.lotId);
  }
}

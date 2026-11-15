import 'package:quadrapp_mobile/contexts/prediction_advisory/domain/entities/next_availability.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// Lectura del tiempo hasta la próxima liberación (US36).
// ignore: one_member_abstracts
abstract interface class NextAvailabilityReader {
  Future<Result<NextAvailability>> read(LotId lotId);
}

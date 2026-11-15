import 'package:quadrapp_mobile/contexts/parking_configuration/domain/entities/calendar_event.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// El calendario del campus de la institución de la sesión (US35). Ambos
/// roles de Operación lo leen, registran y cancelan; un conductor recibe
/// `ForbiddenFailure`.
abstract interface class CampusCalendar {
  /// `GET /calendar-events?from=&to=`: las entradas que se cruzan con el
  /// rango, sin las canceladas.
  Future<Result<List<CalendarEvent>>> list({
    required DateTime from,
    required DateTime to,
  });

  /// `POST /calendar-events` (esc. 1 y 2).
  Future<Result<CalendarEvent>> create(NewCalendarEvent event);

  /// `DELETE /calendar-events/{id}`: la cancela y la predicción deja de
  /// considerarla (esc. 3).
  Future<Result<void>> cancel(CalendarEventId id);
}

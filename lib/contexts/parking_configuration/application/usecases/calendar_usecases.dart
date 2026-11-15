// US35
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/entities/calendar_event.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/repositories/campus_calendar.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

/// El rango del calendario que se consulta.
typedef CalendarWindow = ({DateTime from, DateTime to});

/// Las entradas del calendario que se cruzan con el rango, de la más próxima
/// a la más lejana.
class GetCampusCalendar
    implements UseCase<List<CalendarEvent>, CalendarWindow> {
  const GetCampusCalendar(this._calendar);

  final CampusCalendar _calendar;

  @override
  Future<Result<List<CalendarEvent>>> call(CalendarWindow window) async {
    final result = await _calendar.list(from: window.from, to: window.to);
    return switch (result) {
      Err(:final failure) => Err(failure),
      Success(:final value) => Success(
        List<CalendarEvent>.of(value)
          ..sort((a, b) => a.startsAt.compareTo(b.startsAt)),
      ),
    };
  }
}

/// Registra un periodo académico o un evento del campus (US35 esc. 1 y 2).
class CreateCalendarEvent implements UseCase<CalendarEvent, NewCalendarEvent> {
  const CreateCalendarEvent(this._calendar);

  final CampusCalendar _calendar;

  @override
  Future<Result<CalendarEvent>> call(NewCalendarEvent event) =>
      _calendar.create(event);
}

/// Cancela una entrada (US35 esc. 3).
class CancelCalendarEvent implements UseCase<void, CalendarEventId> {
  const CancelCalendarEvent(this._calendar);

  final CampusCalendar _calendar;

  @override
  Future<Result<void>> call(CalendarEventId id) => _calendar.cancel(id);
}

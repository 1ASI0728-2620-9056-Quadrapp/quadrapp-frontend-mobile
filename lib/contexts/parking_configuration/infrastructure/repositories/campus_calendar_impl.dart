import 'package:quadrapp_mobile/contexts/parking_configuration/domain/entities/calendar_event.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/repositories/campus_calendar.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/datasources/calendar_datasource.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/mappers/calendar_mapper.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/network/failure_mapper.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// El calendario del campus (US35), sin caché.
class CampusCalendarImpl implements CampusCalendar {
  const CampusCalendarImpl({required this._remote, required this._mapper});

  final CalendarRemoteDataSource _remote;
  final CalendarMapper _mapper;

  @override
  Future<Result<List<CalendarEvent>>> list({
    required DateTime from,
    required DateTime to,
  }) => guardResult(
    () async => _mapper.toEvents(await _remote.list(from: from, to: to)),
  );

  @override
  Future<Result<CalendarEvent>> create(NewCalendarEvent event) =>
      guardResult(() async {
        final dto = await _remote.create(_mapper.toRequest(event));
        return _mapper.toEvent(dto);
      });

  @override
  Future<Result<void>> cancel(CalendarEventId id) =>
      guardResult(() => _remote.cancel(id));
}

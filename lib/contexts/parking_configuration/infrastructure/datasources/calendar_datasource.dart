import 'package:dio/dio.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/dto/calendar_event_dto.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/network/parse_exception.dart';

/// Origen remoto del calendario del campus (HTTP o mock).
abstract interface class CalendarRemoteDataSource {
  /// `GET /calendar-events?from=&to=`.
  Future<List<CalendarEventDto>> list({
    required DateTime from,
    required DateTime to,
  });

  /// `POST /calendar-events`.
  Future<CalendarEventDto> create(NewCalendarEventDto request);

  /// `DELETE /calendar-events/{id}`.
  Future<void> cancel(CalendarEventId id);
}

/// `/calendar-events` (docs/07).
class CalendarHttpDataSource implements CalendarRemoteDataSource {
  const CalendarHttpDataSource(this._dio);

  final Dio _dio;

  @override
  Future<List<CalendarEventDto>> list({
    required DateTime from,
    required DateTime to,
  }) async {
    final response = await _dio.get<Object?>(
      '/calendar-events',
      queryParameters: {
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
      },
    );
    final data = response.data;
    if (data is! List) {
      throw const ParseException('El calendario no es una lista.');
    }
    return [
      for (final item in data)
        if (item is Map<String, dynamic>)
          CalendarEventDto.fromJson(item)
        else
          throw const ParseException('Un evento no es un objeto.'),
    ];
  }

  @override
  Future<CalendarEventDto> create(NewCalendarEventDto request) async {
    final response = await _dio.post<Object?>(
      '/calendar-events',
      data: request.toJson(),
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const ParseException('El evento creado no es un objeto.');
    }
    return CalendarEventDto.fromJson(data);
  }

  @override
  Future<void> cancel(CalendarEventId id) async {
    await _dio.delete<Object?>('/calendar-events/${id.value}');
  }
}

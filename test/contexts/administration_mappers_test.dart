// US20, US30, US31, US35: mappers y repositorios de la administración (caso
// feliz, error de red y valores desconocidos del servidor).
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quadrapp_mobile/contexts/iam/iam.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/dto/tenant_dtos.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/mappers/tenant_mapper.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/dto/calendar_event_dto.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/mappers/calendar_mapper.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/infrastructure/datasources/problem_report_datasource.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/infrastructure/dto/problem_report_dto.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/infrastructure/repositories/problem_reporter_impl.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/parking_sensing.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

import '../helpers/recording_logger.dart';

class _MockProblemRemote extends Mock
    implements ProblemReportRemoteDataSource {}

void main() {
  late RecordingLogger logger;

  setUp(() => logger = RecordingLogger());

  test('el equipo omite lo ilegible y un estado desconocido es ACTIVE', () {
    final team = TenantMapper(logger).toTeam(
      TeamDto.fromJson({
        'serverTime': '2026-09-28T13:42:00Z',
        'members': [
          {
            'id': 3,
            'email': 'laura@upc.edu.pe',
            'role': 'ADMIN',
            'status': 'ACTIVE',
            'fullName': 'Laura',
          },
          {
            'id': 6,
            'email': 'mariana@upc.edu.pe',
            'role': 'OPERATOR',
            'status': 'INVITED',
            'invitationExpiresAt': '2026-10-03T13:42:00Z',
          },
          {'id': 8, 'email': 'x@upc.edu.pe', 'role': 'DRIVER', 'status': 'X'},
          {
            'id': 9,
            'email': 'pedro@upc.edu.pe',
            'role': 'OPERATOR',
            'status': 'SUSPENDED',
          },
        ],
      }),
    );
    expect(team.members.map((m) => m.id.value), [3, 9, 6]);
    expect(team.members.last.isInvited, isTrue);
    expect(team.members[1].status, MemberStatus.active);
    expect(logger.messages, hasLength(2));
  });

  test('un dominio ilegible se omite', () {
    final domains = TenantMapper(logger).toDomains([
      const InstitutionDomainDto(id: 1, domain: 'upc.edu.pe'),
      const InstitutionDomainDto(id: 2, domain: '???'),
    ]);
    expect(domains.single.name.value, 'upc.edu.pe');
    expect(domains.single.isVerified, isFalse);
  });

  test('el calendario acepta lo desconocido sin romperse', () {
    final mapper = CalendarMapper(logger);
    final events = mapper.toEvents([
      CalendarEventDto.fromJson({
        'id': 1,
        'type': 'HOLIDAY',
        'name': 'Feriado',
        'impact': 'EXTREME',
        'startsAt': '2026-10-08T05:00:00Z',
        'endsAt': '2026-10-09T05:00:00Z',
      }),
      CalendarEventDto.fromJson({
        'id': 2,
        'type': 'EXAMS',
        'name': 'Al revés',
        'impact': 'LOW',
        'startsAt': '2026-10-09T05:00:00Z',
        'endsAt': '2026-10-08T05:00:00Z',
      }),
    ]);
    expect(events.single.type, CalendarEventType.campusEvent);
    expect(events.single.impact, DemandImpact.medium);
    expect(events.single.isCampusWide, isTrue);
    expect(logger.messages, hasLength(3));

    final request = mapper.toRequest(
      NewCalendarEvent.create(
        type: CalendarEventType.exams,
        name: 'Parciales',
        impact: DemandImpact.high,
        startsAt: DateTime.utc(2026, 10, 5, 5),
        endsAt: DateTime.utc(2026, 10, 10, 5),
      ).valueOrNull!,
    );
    expect(request.toJson(), isNot(contains('lotId')));
    expect(request.toJson()['type'], 'EXAMS');
  });

  test('un error de red al reportar llega como NetworkFailure', () async {
    final remote = _MockProblemRemote();
    registerFallbackValue(
      const ProblemReportRequestDto(lotId: 1, category: 'OTHER'),
    );
    when(() => remote.report(any())).thenThrow(
      DioException(
        requestOptions: RequestOptions(path: '/device-incidents'),
        type: DioExceptionType.connectionError,
      ),
    );
    final report = ProblemReport.create(
      lotId: const LotId(1),
      category: ProblemCategory.noCommunication,
      deviceId: const DeviceId(5),
    ).valueOrNull!;

    final result = await ProblemReporterImpl(remote).report(report);

    expect(result.failureOrNull, isA<NetworkFailure>());
    final sent =
        verify(() => remote.report(captureAny())).captured.single
            as ProblemReportRequestDto;
    expect(sent.toJson(), {
      'lotId': 1,
      'category': 'NO_COMMUNICATION',
      'deviceId': 5,
    });
  });
}

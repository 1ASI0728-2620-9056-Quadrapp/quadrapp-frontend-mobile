// US20, US30, US31, US35: reglas del dominio y casos de uso de la
// administración de la universidad (dominios, equipo, calendario y reportes).
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/repositories/tenant_directory.dart';
import 'package:quadrapp_mobile/contexts/iam/iam.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/domain/repositories/campus_calendar.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/parking_sensing.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

class _MockRegistry extends Mock implements DomainRegistry {}

class _MockCalendar extends Mock implements CampusCalendar {}

TeamMember _member(
  int id,
  String email,
  UserRole role, {
  MemberStatus status = MemberStatus.active,
  String? name,
  DateTime? expires,
}) => TeamMember(
  id: UserId(id),
  email: EmailAddress.create(email).valueOrNull!,
  role: role,
  status: status,
  fullName: name,
  invitationExpiresAt: expires,
);

CalendarEvent _event(int id, DateTime startsAt) => CalendarEvent(
  id: CalendarEventId(id),
  type: CalendarEventType.campusEvent,
  name: 'Evento $id',
  impact: DemandImpact.medium,
  startsAt: startsAt,
  endsAt: startsAt.add(const Duration(hours: 2)),
);

void main() {
  final now = DateTime.utc(2026, 9, 28, 13, 42);

  group('DomainName (US30)', () {
    test('acepta un dominio con @ y mayúsculas, y lo normaliza', () {
      final name = DomainName.create('  @Alumnos.UPC.edu.pe ').valueOrNull!;
      expect(name.value, 'alumnos.upc.edu.pe');
      expect(name.owns('ana@alumnos.upc.edu.pe'), isTrue);
      expect(name.owns('ana@x.alumnos.upc.edu.pe'), isFalse);
    });

    test('rechaza lo que no tiene forma de dominio', () {
      for (final raw in ['', 'upc', 'ana@upc.edu.pe', 'upc..pe', '-upc.pe']) {
        expect(
          DomainName.create(raw).failureOrNull,
          isA<ValidationFailure>(),
          reason: raw,
        );
      }
    });
  });

  group('Team y NewInvitation (US31)', () {
    test('ordena: administradores, operadores y al final las invitaciones', () {
      final team = Team(
        serverTime: now,
        members: [
          _member(
            5,
            'zoe@upc.edu.pe',
            UserRole.operator,
            status: MemberStatus.invited,
          ),
          _member(4, 'carlos@upc.edu.pe', UserRole.operator, name: 'Carlos'),
          _member(3, 'laura@upc.edu.pe', UserRole.admin, name: 'Laura'),
        ],
      );
      expect(team.members.map((m) => m.id.value), [3, 4, 5]);
      expect(team.activeCount, 2);
      expect(team.pendingCount, 1);
    });

    test('una invitación vencida se reconoce con la hora del servidor '
        '(esc. 3)', () {
      final member = _member(
        7,
        'diego@upc.edu.pe',
        UserRole.operator,
        status: MemberStatus.invited,
        expires: now,
      );
      expect(member.invitationExpired(now), isTrue);
      expect(
        member.invitationExpired(now.subtract(const Duration(minutes: 1))),
        isFalse,
      );
    });

    test('solo se invita con un correo válido y un rol de Operación', () {
      expect(
        NewInvitation.validate(email: 'x', role: UserRole.driver),
        {InvitationError.invalidEmail, InvitationError.invalidRole},
      );
      final ok = NewInvitation.create(
        email: 'Ana@UPC.edu.pe',
        role: UserRole.admin,
      ).valueOrNull!;
      expect(ok.email.value, 'ana@upc.edu.pe');
    });
  });

  group('NewCalendarEvent (US35)', () {
    test('valida nombre, fechas y que la zona tenga estacionamiento', () {
      expect(
        NewCalendarEvent.validate(
          name: '  ',
          startsAt: now,
          endsAt: now,
          zoneId: const ZoneId(13),
        ),
        {
          CalendarEventError.nameMissing,
          CalendarEventError.endsBeforeStarts,
          CalendarEventError.zoneWithoutLot,
        },
      );
      final event = NewCalendarEvent.create(
        type: CalendarEventType.campusEvent,
        name: ' Feria ',
        impact: DemandImpact.high,
        startsAt: now,
        endsAt: now.add(const Duration(hours: 8)),
        lotId: const LotId(1),
        zoneId: const ZoneId(13),
      ).valueOrNull!;
      expect(event.name, 'Feria');
    });
  });

  group('ProblemReport (US20)', () {
    test('una descripción vacía no se envía y una muy larga no es válida', () {
      final report = ProblemReport.create(
        lotId: const LotId(1),
        category: ProblemCategory.other,
        detail: '   ',
      ).valueOrNull!;
      expect(report.detail, isNull);
      expect(
        ProblemReport.create(
          lotId: const LotId(1),
          category: ProblemCategory.other,
          detail: 'x' * (ProblemReport.maxDetailLength + 1),
        ).failureOrNull,
        isA<ValidationFailure>(),
      );
    });
  });

  group('casos de uso', () {
    setUpAll(
      () => registerFallbackValue(DomainName.create('a.pe').valueOrNull),
    );

    test('GetInstitutionDomains pone primero los verificados', () async {
      final registry = _MockRegistry();
      when(registry.list).thenAnswer(
        (_) async => Success([
          InstitutionDomain(
            id: const InstitutionDomainId(3),
            name: DomainName.create('posgrado.upc.edu.pe').valueOrNull!,
          ),
          InstitutionDomain(
            id: const InstitutionDomainId(1),
            name: DomainName.create('upc.edu.pe').valueOrNull!,
            verifiedAt: now,
          ),
        ]),
      );

      final result = await GetInstitutionDomains(registry)(const NoParams());

      expect(result.valueOrNull!.map((d) => d.id.value), [1, 3]);
    });

    test('AddInstitutionDomain no envía un dominio inválido', () async {
      final registry = _MockRegistry();

      final result = await AddInstitutionDomain(registry)('no es dominio');

      expect(result.failureOrNull, isA<ValidationFailure>());
      verifyNever(() => registry.add(any()));
    });

    test(
      'GetCampusCalendar ordena de la más próxima a la más lejana',
      () async {
        final calendar = _MockCalendar();
        when(
          () => calendar.list(from: now, to: now.add(const Duration(days: 90))),
        ).thenAnswer(
          (_) async => Success([
            _event(2, now.add(const Duration(days: 5))),
            _event(1, now.add(const Duration(days: 1))),
          ]),
        );

        final result = await GetCampusCalendar(calendar)((
          from: now,
          to: now.add(const Duration(days: 90)),
        ));

        expect(result.valueOrNull!.map((e) => e.id.value), [1, 2]);
      },
    );
  });
}

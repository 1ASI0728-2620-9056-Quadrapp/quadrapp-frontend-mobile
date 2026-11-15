// US20, US30, US31, US35: los cubits de Más y Dispositivos.
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:quadrapp_mobile/composition/devices/devices_cubit.dart';
import 'package:quadrapp_mobile/composition/more/more_cubit.dart';
import 'package:quadrapp_mobile/composition/more/more_overview.dart';
import 'package:quadrapp_mobile/contexts/iam/iam.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/parking_sensing.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

import '../helpers/fake_clock.dart';

class _GetCalendar extends Mock implements GetCampusCalendar {}

class _CreateEvent extends Mock implements CreateCalendarEvent {}

class _CancelEvent extends Mock implements CancelCalendarEvent {}

class _GetDomains extends Mock implements GetInstitutionDomains {}

class _AddDomain extends Mock implements AddInstitutionDomain {}

class _RemoveDomain extends Mock implements RemoveInstitutionDomain {}

class _GetTeam extends Mock implements GetTeam {}

class _Invite extends Mock implements InviteTeamMember {}

class _GetInventory extends Mock implements GetDeviceInventory {}

class _Report extends Mock implements ReportDeviceProblem {}

final DateTime _now = DateTime.utc(2026, 9, 28, 13, 42);

CalendarEvent _event(int id, int inDays) => CalendarEvent(
  id: CalendarEventId(id),
  type: CalendarEventType.campusEvent,
  name: 'Evento $id',
  impact: DemandImpact.medium,
  startsAt: _now.add(Duration(days: inDays)),
  endsAt: _now.add(Duration(days: inDays, hours: 3)),
);

InstitutionDomain _domain(int id, String name) => InstitutionDomain(
  id: InstitutionDomainId(id),
  name: DomainName.create(name).valueOrNull!,
  verifiedAt: _now,
);

void main() {
  late _GetCalendar getCalendar;
  late _CreateEvent createEvent;
  late _CancelEvent cancelEvent;
  late _GetDomains getDomains;
  late _AddDomain addDomain;
  late _RemoveDomain removeDomain;
  late _GetTeam getTeam;
  late _Invite invite;

  setUpAll(() {
    registerFallbackValue((from: _now, to: _now));
    registerFallbackValue(const NoParams());
    registerFallbackValue(const LotId(1));
    registerFallbackValue(
      ProblemReport.create(
        lotId: const LotId(1),
        category: ProblemCategory.other,
      ).valueOrNull,
    );
    registerFallbackValue(
      NewInvitation.create(
        email: 'a@upc.edu.pe',
        role: UserRole.operator,
      ).valueOrNull,
    );
  });

  setUp(() {
    getCalendar = _GetCalendar();
    createEvent = _CreateEvent();
    cancelEvent = _CancelEvent();
    getDomains = _GetDomains();
    addDomain = _AddDomain();
    removeDomain = _RemoveDomain();
    getTeam = _GetTeam();
    invite = _Invite();
    when(() => getCalendar(any())).thenAnswer(
      (_) async => Success([_event(1, 1), _event(2, 5)]),
    );
    when(() => getDomains(any())).thenAnswer(
      (_) async => Success([_domain(1, 'upc.edu.pe')]),
    );
    when(() => getTeam(any())).thenAnswer(
      (_) async => Success(Team(members: const [], serverTime: _now)),
    );
  });

  MoreCubit buildMore() => MoreCubit(
    getCampusCalendar: getCalendar,
    createCalendarEvent: createEvent,
    cancelCalendarEvent: cancelEvent,
    getInstitutionDomains: getDomains,
    addInstitutionDomain: addDomain,
    removeInstitutionDomain: removeDomain,
    getTeam: getTeam,
    inviteTeamMember: invite,
    clock: FakeClock(_now),
  );

  group('MoreCubit', () {
    blocTest<MoreCubit, ViewState<MoreOverview>>(
      'pide el calendario desde la medianoche de hoy en Lima, 90 días',
      build: buildMore,
      act: (cubit) => cubit.load(),
      expect: () => [
        isA<ViewLoading<MoreOverview>>(),
        isA<ViewData<MoreOverview>>().having(
          (s) => s.data.events!.length,
          'events',
          2,
        ),
      ],
      verify: (_) => verify(
        () => getCalendar((
          from: DateTime.utc(2026, 9, 28, 5),
          to: DateTime.utc(2026, 12, 27, 5),
        )),
      ).called(1),
    );

    blocTest<MoreCubit, ViewState<MoreOverview>>(
      'una parte que falla deja la respuesta parcial',
      setUp: () => when(
        () => getTeam(any()),
      ).thenAnswer((_) async => const Err(ServerFailure())),
      build: buildMore,
      act: (cubit) => cubit.load(),
      skip: 1,
      expect: () => [
        isA<ViewPartial<MoreOverview>>()
            .having((s) => s.missing, 'missing', {'team'})
            .having((s) => s.data.domains, 'domains', isNotNull),
      ],
    );

    blocTest<MoreCubit, ViewState<MoreOverview>>(
      'el 403 es un error',
      setUp: () => when(
        () => getCalendar(any()),
      ).thenAnswer((_) async => const Err(ForbiddenFailure())),
      build: buildMore,
      act: (cubit) => cubit.load(),
      skip: 1,
      expect: () => [isA<ViewError<MoreOverview>>()],
    );

    test(
      'cancelar un evento lo quita de la lista sin volver a pedir todo',
      () async {
        when(
          () => cancelEvent(const CalendarEventId(1)),
        ).thenAnswer((_) async => const Success(null));
        final cubit = buildMore();
        await cubit.load();

        final failure = await cubit.cancelEvent(const CalendarEventId(1));

        expect(failure, isNull);
        final state = cubit.state as ViewData<MoreOverview>;
        expect(state.data.events!.map((e) => e.id.value), [2]);
        verify(() => getCalendar(any())).called(1);
        await cubit.close();
      },
    );

    test(
      'una invitación inválida no llega al servidor; una válida se suma',
      () async {
        final member = TeamMember(
          id: const UserId(20),
          email: EmailAddress.create('ana@upc.edu.pe').valueOrNull!,
          role: UserRole.operator,
          status: MemberStatus.invited,
        );
        when(
          () => invite(any()),
        ).thenAnswer((_) async => Success(InvitationReceipt(member: member)));
        final cubit = buildMore();
        await cubit.load();

        final invalid = await cubit.invite(email: 'ana', role: UserRole.admin);
        final valid = await cubit.invite(
          email: 'ana@upc.edu.pe',
          role: UserRole.operator,
        );

        expect(invalid, isA<ValidationFailure>());
        expect(valid, isNull);
        verify(() => invite(any())).called(1);
        final state = cubit.state as ViewData<MoreOverview>;
        expect(state.data.team!.pendingCount, 1);
        await cubit.close();
      },
    );

    test(
      'un dominio de otra institución devuelve la falla (US30 esc. 3)',
      () async {
        when(() => addDomain('pucp.edu.pe')).thenAnswer(
          (_) async => const Err(
            ValidationFailure('Conflict', {
              'domain': ['taken'],
            }),
          ),
        );
        final cubit = buildMore();
        await cubit.load();

        final failure = await cubit.addDomain('pucp.edu.pe');

        expect(failure, isA<ValidationFailure>());
        final state = cubit.state as ViewData<MoreOverview>;
        expect(state.data.domains, hasLength(1));
        await cubit.close();
      },
    );
  });

  group('DevicesCubit', () {
    late _GetInventory inventory;
    late _Report report;

    setUp(() {
      inventory = _GetInventory();
      report = _Report();
    });

    DevicesCubit build() => DevicesCubit(
      getDeviceInventory: inventory,
      reportDeviceProblem: report,
    );

    blocTest<DevicesCubit, ViewState<DeviceInventory>>(
      'sin dispositivos es el estado vacío',
      setUp: () => when(() => inventory(any())).thenAnswer(
        (_) async => Success(
          DeviceInventory(
            lotId: const LotId(3),
            devices: const [],
            serverTime: _now,
            receivedAt: Duration.zero,
          ),
        ),
      ),
      build: build,
      act: (cubit) => cubit.load(const LotId(3)),
      expect: () => [
        isA<ViewLoading<DeviceInventory>>(),
        isA<ViewEmpty<DeviceInventory>>(),
      ],
    );

    test('el reporte lleva el estacionamiento actual', () async {
      when(() => inventory(any())).thenAnswer(
        (_) async => const Err(NetworkFailure()),
      );
      when(() => report(any())).thenAnswer(
        (_) async => Success(
          ProblemReceipt(id: const DeviceIncidentId(1), reportedAt: _now),
        ),
      );
      final cubit = build();
      await cubit.load(const LotId(4));

      final result = await cubit.report(
        category: ProblemCategory.noCommunication,
        deviceId: const DeviceId(9),
      );

      expect(result.valueOrNull, isNotNull);
      final sent =
          verify(() => report(captureAny())).captured.single as ProblemReport;
      expect(sent.lotId, const LotId(4));
      expect(sent.deviceId, const DeviceId(9));
      await cubit.close();
    });
  });
}

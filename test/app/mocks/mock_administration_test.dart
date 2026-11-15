// Datos de prueba de la administración: dominios, equipo, calendario y
// reportes, con sus permisos (US20, US30, US31, US35).
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quadrapp_mobile/app/mocks/mock_world.dart';
import 'package:quadrapp_mobile/app/mocks/tenant/mock_tenant_datasources.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/dto/tenant_dtos.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/dto/calendar_event_dto.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/infrastructure/dto/problem_report_dto.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/test_seed.dart';

final DateTime _now = DateTime.utc(2026, 9, 28, 13, 42);

MockWorld _world() => MockWorld(
  seed: testSeed,
  clock: FakeClock(_now),
  random: Random(1),
  latency: false,
);

/// El código y el primer motivo de `errors[field]`, o `null` si no falló.
Future<(int?, String?)?> _error(
  Future<void> Function() call, [
  String? field,
]) async {
  try {
    await call();
    return null;
  } on DioException catch (error) {
    final data = error.response?.data;
    String? reason;
    if (field != null && data is Map) {
      final errors = data['errors'];
      if (errors is Map) reason = (errors[field] as List?)?.first as String?;
    }
    return (error.response?.statusCode, reason);
  }
}

void main() {
  group('dominios (US30)', () {
    test(
      'el operador los ve pero no los cambia; el conductor no los ve',
      () async {
        final world = _world();
        final operator = MockTenantRemoteDataSource(world, () => 'OPERATOR');
        expect(await operator.domains(), hasLength(3));
        expect(
          await _error(
            () => operator.addDomain(const AddDomainRequestDto(domain: 'a.pe')),
          ),
          (403, null),
        );
        final driver = MockTenantRemoteDataSource(world, () => 'DRIVER');
        expect(await _error(driver.domains), (403, null));
      },
    );

    test(
      'uno nuevo nace pendiente; uno de otra institución es 409 (esc. 3)',
      () async {
        final admin = MockTenantRemoteDataSource(_world(), () => 'ADMIN');
        final created = await admin.addDomain(
          const AddDomainRequestDto(domain: 'Docentes.UPC.edu.pe'),
        );
        expect(created.domain, 'docentes.upc.edu.pe');
        expect(created.verifiedAt, isNull);
        expect(
          await _error(
            () => admin.addDomain(
              const AddDomainRequestDto(domain: 'pucp.edu.pe'),
            ),
            'domain',
          ),
          (409, 'taken'),
        );
        await admin.removeDomain(InstitutionDomainId(created.id));
        expect(await admin.domains(), hasLength(3));
      },
    );
  });

  group('equipo (US31)', () {
    test('el equipo incluye a quien administra y las invitaciones', () async {
      final admin = MockTenantRemoteDataSource(_world(), () => 'ADMIN');
      final team = await admin.team();
      expect(
        team.members.map((m) => m.email),
        contains('administrador@upc.edu.pe'),
      );
      expect(team.members.where((m) => m.status == 'INVITED'), hasLength(2));
    });

    test('solo se invita con un dominio verificado y sin cuenta vigente; '
        'una invitación vencida se reemplaza', () async {
      final admin = MockTenantRemoteDataSource(_world(), () => 'ADMIN');
      expect(
        await _error(
          () => admin.invite(
            const InvitationRequestDto(
              email: 'ana@posgrado.upc.edu.pe',
              role: 'OPERATOR',
            ),
          ),
          'email',
        ),
        (400, 'domain'),
      );
      expect(
        await _error(
          () => admin.invite(
            const InvitationRequestDto(
              email: 'carlos.rivas@upc.edu.pe',
              role: 'OPERATOR',
            ),
          ),
          'email',
        ),
        (409, 'taken'),
      );
      final renewed = await admin.invite(
        const InvitationRequestDto(
          email: 'diego.paz@upc.edu.pe',
          role: 'ADMIN',
        ),
      );
      expect(renewed.status, 'INVITED');
      expect(renewed.invitationExpiresAt, _now.add(const Duration(days: 7)));
    });
  });

  group('calendario (US35)', () {
    test(
      'lista lo que se cruza con el rango, con los nombres del alcance',
      () async {
        final source = MockCalendarRemoteDataSource(_world(), () => 'OPERATOR');
        final events = await source.list(
          from: _now,
          to: _now.add(const Duration(days: 90)),
        );
        expect(events.map((e) => e.name), [
          'Clases del ciclo',
          'Exámenes parciales',
          'Feria universitaria',
          'Día sin clases',
        ]);
        final fair = events[2];
        expect(fair.lotName, 'Monterrico');
        expect(fair.zoneName, isNotNull);
        // 09:00 de Lima, cinco días después.
        expect(fair.startsAt, DateTime.utc(2026, 10, 3, 14));
      },
    );

    test(
      'el operador registra y cancela; una zona de otro lote es 400',
      () async {
        final source = MockCalendarRemoteDataSource(_world(), () => 'OPERATOR');
        final created = await source.create(
          NewCalendarEventDto(
            type: 'CAMPUS_EVENT',
            name: 'Feria de empleo',
            impact: 'HIGH',
            startsAt: _now.add(const Duration(days: 2)),
            endsAt: _now.add(const Duration(days: 2, hours: 8)),
            lotId: 1,
          ),
        );
        await source.cancel(CalendarEventId(created.id));
        final events = await source.list(
          from: _now,
          to: _now.add(const Duration(days: 90)),
        );
        expect(events.map((e) => e.id), isNot(contains(created.id)));
        expect(
          await _error(
            () => source.create(
              NewCalendarEventDto(
                type: 'CAMPUS_EVENT',
                name: 'X',
                impact: 'LOW',
                startsAt: _now,
                endsAt: _now.add(const Duration(hours: 1)),
                lotId: 1,
                zoneId: 41,
              ),
            ),
            'zoneId',
          ),
          (400, 'not in lot'),
        );
      },
    );
  });

  test('un reporte queda en la bitácora (US20)', () async {
    final world = _world();
    final source = MockProblemReportRemoteDataSource(world, () => 'OPERATOR');
    final deviceId = world.devicesOf(1).first.id;
    final receipt = await source.report(
      ProblemReportRequestDto(
        lotId: 1,
        category: 'NO_COMMUNICATION',
        deviceId: deviceId,
      ),
    );
    expect(receipt.detectedAt, _now);
    expect(world.tenant.incidents.single.deviceId, deviceId);
    expect(
      await _error(
        () => source.report(
          const ProblemReportRequestDto(lotId: 1, category: 'FIRE'),
        ),
        'category',
      ),
      (400, 'invalid'),
    );
  });
}

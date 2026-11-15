import 'package:quadrapp_mobile/app/mocks/mock_errors.dart';
import 'package:quadrapp_mobile/app/mocks/mock_world.dart';
import 'package:quadrapp_mobile/app/mocks/tenant/mock_tenant_state.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/datasources/tenant_remote_datasource.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/dto/tenant_dtos.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/datasources/calendar_datasource.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/infrastructure/dto/calendar_event_dto.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/infrastructure/datasources/problem_report_datasource.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/infrastructure/dto/problem_report_dto.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';

Never _invalid(String field, String code, {int status = 400}) =>
    throw mockHttpError(
      status,
      title: status == 409 ? 'Conflict' : 'Bad Request',
      extra: {
        'errors': {
          field: [code],
        },
      },
    );

Never _forbidden() => throw mockHttpError(
  403,
  title: 'Forbidden',
  detail: 'Solo un administrador de la universidad hace esta acción.',
);

/// `/tenant/*` desde [MockWorld] (US30, US31). Leer lo atiende cualquier rol
/// de Operación; agregar o retirar dominios e invitar, solo `ADMIN` (403 al
/// operador). Un conductor recibe 403 en todo.
class MockTenantRemoteDataSource implements TenantRemoteDataSource {
  const MockTenantRemoteDataSource(this._world, this._callerRole);

  final MockWorld _world;
  final String? Function() _callerRole;

  MockTenantState get _state => _world.tenant;

  Future<void> _gateAdmin() async {
    final role = _callerRole();
    await _world.gateConsole(role);
    if (role != 'ADMIN') _forbidden();
  }

  static InstitutionDomainDto _domain(MockDomain d) => InstitutionDomainDto(
    id: d.id,
    domain: d.domain,
    verifiedAt: d.verifiedAt,
  );

  static TeamMemberDto _member(MockMember m) => TeamMemberDto(
    id: m.id,
    email: m.email,
    role: m.role,
    status: m.status,
    fullName: m.fullName,
    invitationExpiresAt: m.invitationExpiresAt,
  );

  @override
  Future<List<InstitutionDomainDto>> domains() async {
    await _world.gateConsole(_callerRole());
    return [for (final d in _state.domains) _domain(d)];
  }

  /// Como el servidor: forma válida, no repetido en la institución (409
  /// `duplicate`) ni de otra institución (409 `taken`, US30 esc. 3). Nace
  /// pendiente.
  @override
  Future<InstitutionDomainDto> addDomain(AddDomainRequestDto request) async {
    await _gateAdmin();
    final domain = request.domain.trim().toLowerCase();
    if (!RegExp(r'^[a-z0-9-]+(\.[a-z0-9-]+)+$').hasMatch(domain)) {
      _invalid('domain', 'invalid');
    }
    if (_state.domains.any((d) => d.domain == domain)) {
      _invalid('domain', 'duplicate', status: 409);
    }
    if (_state.otherInstitutionDomains.contains(domain)) {
      _invalid('domain', 'taken', status: 409);
    }
    final created = MockDomain(id: _state.nextId(), domain: domain);
    _state.domains.add(created);
    return _domain(created);
  }

  @override
  Future<void> removeDomain(InstitutionDomainId id) async {
    await _gateAdmin();
    final before = _state.domains.length;
    _state.domains.removeWhere((d) => d.id == id.value);
    if (_state.domains.length == before) {
      throw mockHttpError(404, title: 'Not Found');
    }
  }

  @override
  Future<TeamDto> team() async {
    await _world.gateConsole(_callerRole());
    return TeamDto(
      serverTime: _world.clock.now(),
      members: [for (final m in _state.members) _member(m)],
    );
  }

  /// Como el servidor: correo de un dominio verificado (400 `domain`), rol de
  /// Operación y sin cuenta ni invitación vigente (409 `taken`). Una
  /// invitación vencida se reemplaza por la nueva.
  @override
  Future<TeamMemberDto> invite(InvitationRequestDto request) async {
    await _gateAdmin();
    final email = request.email.trim().toLowerCase();
    if (request.role != 'ADMIN' && request.role != 'OPERATOR') {
      _invalid('role', 'invalid');
    }
    if (!_state.hasVerifiedDomainFor(email)) _invalid('email', 'domain');
    final now = _world.clock.now();
    final existing = _state.members.where((m) => m.email == email).firstOrNull;
    if (existing != null) {
      final expired =
          existing.status == 'INVITED' &&
          !now.isBefore(existing.invitationExpiresAt ?? now);
      if (!expired) _invalid('email', 'taken', status: 409);
      _state.members.remove(existing);
    }
    final member = MockMember(
      id: _state.nextId(),
      email: email,
      role: request.role,
      status: 'INVITED',
      invitationExpiresAt: now.add(MockTenantState.invitationValidity),
    );
    _state.members.add(member);
    return _member(member);
  }
}

/// `/calendar-events` desde [MockWorld] (US35). Ambos roles de Operación lo
/// leen, registran y cancelan.
class MockCalendarRemoteDataSource implements CalendarRemoteDataSource {
  const MockCalendarRemoteDataSource(this._world, this._callerRole);

  final MockWorld _world;
  final String? Function() _callerRole;

  CalendarEventDto _dto(MockCalendarEvent e) {
    final lot = e.lotId == null ? null : _world.lot(e.lotId!);
    final zone = lot?.zones.where((z) => z.id == e.zoneId).firstOrNull;
    return CalendarEventDto(
      id: e.id,
      type: e.type,
      name: e.name,
      impact: e.impact,
      startsAt: e.startsAt,
      endsAt: e.endsAt,
      lotId: e.lotId,
      lotName: lot?.name,
      zoneId: e.zoneId,
      zoneName: zone?.name,
    );
  }

  @override
  Future<List<CalendarEventDto>> list({
    required DateTime from,
    required DateTime to,
  }) async {
    await _world.gateConsole(_callerRole());
    if (!from.isBefore(to)) _invalid('from', 'must be before to');
    return [
      for (final e in _world.tenant.events)
        if (e.cancelledAt == null &&
            e.startsAt.isBefore(to) &&
            e.endsAt.isAfter(from))
          _dto(e),
    ];
  }

  @override
  Future<CalendarEventDto> create(NewCalendarEventDto request) async {
    await _world.gateConsole(_callerRole());
    const types = {'CLASSES', 'EXAMS', 'RECESS', 'CAMPUS_EVENT'};
    const impacts = {'LOW', 'MEDIUM', 'HIGH'};
    final name = request.name.trim();
    if (name.isEmpty || name.length > 120) _invalid('name', 'invalid');
    if (!types.contains(request.type)) _invalid('type', 'invalid');
    if (!impacts.contains(request.impact)) _invalid('impact', 'invalid');
    if (!request.endsAt.isAfter(request.startsAt)) {
      _invalid('endsAt', 'must be after startsAt');
    }
    final lotId = request.lotId;
    final zoneId = request.zoneId;
    if (zoneId != null && lotId == null) _invalid('zoneId', 'requires lotId');
    if (lotId != null) {
      final lot = _world.lot(lotId);
      if (lot == null) _invalid('lotId', 'not found');
      if (zoneId != null && !lot.zones.any((z) => z.id == zoneId)) {
        _invalid('zoneId', 'not in lot');
      }
    }
    final event = MockCalendarEvent(
      id: _world.tenant.nextId(),
      type: request.type,
      name: name,
      impact: request.impact,
      startsAt: request.startsAt.toUtc(),
      endsAt: request.endsAt.toUtc(),
      lotId: lotId,
      zoneId: zoneId,
    );
    _world.tenant.events.add(event);
    return _dto(event);
  }

  @override
  Future<void> cancel(CalendarEventId id) async {
    await _world.gateConsole(_callerRole());
    final event = _world.tenant.events
        .where((e) => e.id == id.value && e.cancelledAt == null)
        .firstOrNull;
    if (event == null) throw mockHttpError(404, title: 'Not Found');
    event.cancelledAt = _world.clock.now();
  }
}

/// `POST /device-incidents` desde [MockWorld]: el reporte queda en la
/// bitácora como `USER_REPORT`. Ambos roles de Operación reportan.
class MockProblemReportRemoteDataSource
    implements ProblemReportRemoteDataSource {
  const MockProblemReportRemoteDataSource(this._world, this._callerRole);

  final MockWorld _world;
  final String? Function() _callerRole;

  @override
  Future<ProblemReceiptDto> report(ProblemReportRequestDto request) async {
    await _world.gateConsole(_callerRole());
    const categories = {
      'NO_COMMUNICATION',
      'WRONG_DATA',
      'LOW_BATTERY',
      'OTHER',
    };
    if (_world.lot(request.lotId) == null) {
      throw mockHttpError(404, title: 'Not Found');
    }
    if (!categories.contains(request.category)) _invalid('category', 'invalid');
    final deviceId = request.deviceId;
    if (deviceId != null &&
        !_world.devicesOf(request.lotId).any((d) => d.id == deviceId)) {
      _invalid('deviceId', 'not in lot');
    }
    if ((request.detail?.length ?? 0) > 1000) _invalid('detail', 'tooLong');
    final incident = MockIncident(
      id: _world.tenant.nextId(),
      lotId: request.lotId,
      category: request.category,
      detectedAt: _world.clock.now(),
      deviceId: deviceId,
      detail: request.detail,
    );
    _world.tenant.incidents.add(incident);
    return ProblemReceiptDto(id: incident.id, detectedAt: incident.detectedAt);
  }
}

import 'package:quadrapp_mobile/app/mocks/mock_seed.dart';

/// Un dominio de correo de la institución de prueba.
class MockDomain {
  MockDomain({required this.id, required this.domain, this.verifiedAt});

  final int id;
  final String domain;
  DateTime? verifiedAt;
}

/// Una persona del equipo de Operación (con cuenta o invitada).
class MockMember {
  MockMember({
    required this.id,
    required this.email,
    required this.role,
    required this.status,
    this.fullName,
    this.invitationExpiresAt,
  });

  final int id;
  final String email;
  final String role;
  final String status;
  final String? fullName;
  final DateTime? invitationExpiresAt;
}

/// Una entrada del calendario del campus.
class MockCalendarEvent {
  MockCalendarEvent({
    required this.id,
    required this.type,
    required this.name,
    required this.impact,
    required this.startsAt,
    required this.endsAt,
    this.lotId,
    this.zoneId,
  });

  final int id;
  final String type;
  final String name;
  final String impact;
  final DateTime startsAt;
  final DateTime endsAt;
  final int? lotId;
  final int? zoneId;
  DateTime? cancelledAt;
}

/// Un reporte de problema recibido (`USER_REPORT`).
class MockIncident {
  MockIncident({
    required this.id,
    required this.lotId,
    required this.category,
    required this.detectedAt,
    this.deviceId,
    this.detail,
  });

  final int id;
  final int lotId;
  final String category;
  final DateTime detectedAt;
  final int? deviceId;
  final String? detail;
}

/// La administración de la institución de prueba: dominios, equipo,
/// calendario e incidencias reportadas (docs/07, "Datos y comportamiento de
/// los mocks"). Las fechas de la semilla son relativas a hoy en Lima, para
/// que nunca queden viejas.
class MockTenantState {
  MockTenantState(MockSeed seed, DateTime now) {
    load(seed, now);
  }

  static const Duration _lima = Duration(hours: -5);

  /// Vigencia de una invitación nueva (US31 esc. 1).
  static const Duration invitationValidity = Duration(days: 7);

  final List<MockDomain> domains = [];
  final Set<String> otherInstitutionDomains = {};
  final List<MockMember> members = [];
  final List<MockCalendarEvent> events = [];
  final List<MockIncident> incidents = [];
  int _nextId = 100;

  int nextId() => _nextId++;

  /// Vuelve a los datos de la semilla.
  void load(MockSeed seed, DateTime now) {
    domains.clear();
    otherInstitutionDomains.clear();
    members.clear();
    events.clear();
    incidents.clear();
    _nextId = 100;

    final tenant = seed.tenant;
    for (final raw in tenant['domains'] as List<dynamic>? ?? const []) {
      final map = raw as Map<String, dynamic>;
      final days = map['verifiedDaysAgo'] as int?;
      domains.add(
        MockDomain(
          id: map['id'] as int,
          domain: map['domain'] as String,
          verifiedAt: days == null ? null : now.subtract(Duration(days: days)),
        ),
      );
    }
    otherInstitutionDomains.addAll(
      (tenant['otherInstitutionDomains'] as List<dynamic>? ?? const [])
          .cast<String>(),
    );

    // Los usuarios de Operación de la semilla también son del equipo.
    for (final user in seed.users) {
      if (user.role == 'ADMIN' || user.role == 'OPERATOR') {
        members.add(
          MockMember(
            id: user.id,
            email: user.email,
            role: user.role,
            status: 'ACTIVE',
            fullName: user.fullName,
          ),
        );
      }
    }
    for (final raw in tenant['team'] as List<dynamic>? ?? const []) {
      final map = raw as Map<String, dynamic>;
      final days = map['invitationExpiresInDays'] as int?;
      members.add(
        MockMember(
          id: map['id'] as int,
          email: map['email'] as String,
          role: map['role'] as String,
          status: map['status'] as String,
          fullName: map['fullName'] as String?,
          invitationExpiresAt: days == null
              ? null
              : now.add(Duration(days: days)),
        ),
      );
    }

    final local = now.add(_lima);
    DateTime at(int day, String? hhmm) {
      final parts = (hhmm ?? '00:00').split(':');
      return DateTime.utc(
        local.year,
        local.month,
        local.day + day,
        int.parse(parts[0]),
        int.parse(parts[1]),
      ).subtract(_lima);
    }

    for (final map in seed.calendarEvents) {
      final startDay = map['startDay'] as int;
      final startTime = map['startTime'] as String?;
      final endTime = map['endTime'] as String?;
      // Un periodo ocupa días completos (hasta la medianoche siguiente a su
      // último día); un evento, su horario.
      final endsAt = endTime != null
          ? at(startDay, endTime)
          : at((map['endDay'] as int? ?? startDay) + 1, null);
      events.add(
        MockCalendarEvent(
          id: map['id'] as int,
          type: map['type'] as String,
          name: map['name'] as String,
          impact: map['impact'] as String,
          startsAt: at(startDay, startTime),
          endsAt: endsAt,
          lotId: map['lotId'] as int?,
          zoneId: map['zoneId'] as int?,
        ),
      );
    }
  }

  /// ¿[email] es de un dominio verificado de la institución?
  bool hasVerifiedDomainFor(String email) => domains.any(
    (d) => d.verifiedAt != null && email.toLowerCase().endsWith('@${d.domain}'),
  );
}

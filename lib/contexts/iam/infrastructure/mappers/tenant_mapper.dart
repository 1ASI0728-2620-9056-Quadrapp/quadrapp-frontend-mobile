import 'package:quadrapp_mobile/contexts/iam/domain/entities/institution_domain.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/entities/team.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/email_address.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/user_role.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/dto/tenant_dtos.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/logging/logger.dart';
import 'package:quadrapp_mobile/core/network/parse_exception.dart';

/// DTO <-> entidades de la administración de la institución. Un valor
/// desconocido del servidor no rompe la pantalla:
/// - un dominio o una persona con un correo o dominio ilegible se omite;
/// - una persona con un rol que no es de Operación se omite (el equipo es de
///   Operación);
/// - un `status` desconocido se trata como `ACTIVE`.
/// Cada caso deja un aviso sin datos personales.
class TenantMapper {
  const TenantMapper(this._logger);

  final Logger _logger;

  List<InstitutionDomain> toDomains(List<InstitutionDomainDto> dtos) => [
    for (final dto in dtos) ?_domainOrNull(dto),
  ];

  /// La respuesta de `POST /tenant/domains`: ilegible es `ParseFailure`.
  InstitutionDomain toDomain(InstitutionDomainDto dto) =>
      _domainOrNull(dto) ??
      (throw const ParseException('El dominio no es válido.'));

  InstitutionDomain? _domainOrNull(InstitutionDomainDto dto) {
    final name = DomainName.create(dto.domain).valueOrNull;
    if (name == null) {
      _logger.warning('Dominio ilegible: se omite');
      return null;
    }
    return InstitutionDomain(
      id: InstitutionDomainId(dto.id),
      name: name,
      verifiedAt: dto.verifiedAt?.toUtc(),
    );
  }

  Team toTeam(TeamDto dto) => Team(
    serverTime: dto.serverTime.toUtc(),
    members: [for (final member in dto.members) ?_memberOrNull(member)],
  );

  /// La respuesta de `POST /tenant/invitations`.
  TeamMember toMember(TeamMemberDto dto) =>
      _memberOrNull(dto) ??
      (throw const ParseException('La persona invitada no es válida.'));

  TeamMember? _memberOrNull(TeamMemberDto dto) {
    final email = EmailAddress.create(dto.email).valueOrNull;
    final role = switch (dto.role.toUpperCase()) {
      'ADMIN' => UserRole.admin,
      'OPERATOR' => UserRole.operator,
      _ => null,
    };
    if (email == null || role == null) {
      _logger.warning('Persona del equipo ilegible o sin rol de Operación');
      return null;
    }
    final status = switch (dto.status.toUpperCase()) {
      'INVITED' => MemberStatus.invited,
      'ACTIVE' => MemberStatus.active,
      _ => null,
    };
    if (status == null) {
      _logger.warning('Estado de persona no reconocido: ACTIVE');
    }
    return TeamMember(
      id: UserId(dto.id),
      email: email,
      role: role,
      status: status ?? MemberStatus.active,
      fullName: dto.fullName,
      invitationExpiresAt: dto.invitationExpiresAt?.toUtc(),
    );
  }

  InvitationRequestDto toInvitation(NewInvitation invitation) =>
      InvitationRequestDto(
        email: invitation.email.value,
        role: switch (invitation.role) {
          UserRole.admin => 'ADMIN',
          UserRole.operator || UserRole.driver => 'OPERATOR',
        },
      );
}

import 'package:json_annotation/json_annotation.dart';

part 'tenant_dtos.g.dart';

/// Un dominio de `GET/POST /tenant/domains` (docs/07).
@JsonSerializable()
class InstitutionDomainDto {
  const InstitutionDomainDto({
    required this.id,
    required this.domain,
    this.verifiedAt,
  });

  factory InstitutionDomainDto.fromJson(Map<String, dynamic> json) =>
      _$InstitutionDomainDtoFromJson(json);

  final int id;
  final String domain;

  /// `null`: pendiente de verificación.
  final DateTime? verifiedAt;

  Map<String, dynamic> toJson() => _$InstitutionDomainDtoToJson(this);
}

/// El cuerpo de `POST /tenant/domains`.
@JsonSerializable()
class AddDomainRequestDto {
  const AddDomainRequestDto({required this.domain});

  factory AddDomainRequestDto.fromJson(Map<String, dynamic> json) =>
      _$AddDomainRequestDtoFromJson(json);

  final String domain;

  Map<String, dynamic> toJson() => _$AddDomainRequestDtoToJson(this);
}

/// Una persona del equipo: cada elemento de `GET /tenant/team` y la
/// respuesta de `POST /tenant/invitations`.
@JsonSerializable()
class TeamMemberDto {
  const TeamMemberDto({
    required this.id,
    required this.email,
    required this.role,
    required this.status,
    this.fullName,
    this.invitationExpiresAt,
  });

  factory TeamMemberDto.fromJson(Map<String, dynamic> json) =>
      _$TeamMemberDtoFromJson(json);

  final int id;
  final String email;

  /// `ADMIN` u `OPERATOR`.
  final String role;

  /// `ACTIVE` o `INVITED`.
  final String status;
  final String? fullName;
  final DateTime? invitationExpiresAt;

  Map<String, dynamic> toJson() => _$TeamMemberDtoToJson(this);
}

/// `GET /tenant/team`.
@JsonSerializable(explicitToJson: true)
class TeamDto {
  const TeamDto({required this.serverTime, required this.members});

  factory TeamDto.fromJson(Map<String, dynamic> json) =>
      _$TeamDtoFromJson(json);

  final DateTime serverTime;
  final List<TeamMemberDto> members;

  Map<String, dynamic> toJson() => _$TeamDtoToJson(this);
}

/// El cuerpo de `POST /tenant/invitations`.
@JsonSerializable()
class InvitationRequestDto {
  const InvitationRequestDto({required this.email, required this.role});

  factory InvitationRequestDto.fromJson(Map<String, dynamic> json) =>
      _$InvitationRequestDtoFromJson(json);

  final String email;
  final String role;

  Map<String, dynamic> toJson() => _$InvitationRequestDtoToJson(this);
}

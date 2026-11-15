// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant_dtos.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InstitutionDomainDto _$InstitutionDomainDtoFromJson(
  Map<String, dynamic> json,
) => InstitutionDomainDto(
  id: (json['id'] as num).toInt(),
  domain: json['domain'] as String,
  verifiedAt: json['verifiedAt'] == null
      ? null
      : DateTime.parse(json['verifiedAt'] as String),
);

Map<String, dynamic> _$InstitutionDomainDtoToJson(
  InstitutionDomainDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'domain': instance.domain,
  'verifiedAt': instance.verifiedAt?.toIso8601String(),
};

AddDomainRequestDto _$AddDomainRequestDtoFromJson(Map<String, dynamic> json) =>
    AddDomainRequestDto(domain: json['domain'] as String);

Map<String, dynamic> _$AddDomainRequestDtoToJson(
  AddDomainRequestDto instance,
) => <String, dynamic>{'domain': instance.domain};

TeamMemberDto _$TeamMemberDtoFromJson(Map<String, dynamic> json) =>
    TeamMemberDto(
      id: (json['id'] as num).toInt(),
      email: json['email'] as String,
      role: json['role'] as String,
      status: json['status'] as String,
      fullName: json['fullName'] as String?,
      invitationExpiresAt: json['invitationExpiresAt'] == null
          ? null
          : DateTime.parse(json['invitationExpiresAt'] as String),
    );

Map<String, dynamic> _$TeamMemberDtoToJson(TeamMemberDto instance) =>
    <String, dynamic>{
      'id': instance.id,
      'email': instance.email,
      'role': instance.role,
      'status': instance.status,
      'fullName': instance.fullName,
      'invitationExpiresAt': instance.invitationExpiresAt?.toIso8601String(),
    };

TeamDto _$TeamDtoFromJson(Map<String, dynamic> json) => TeamDto(
  serverTime: DateTime.parse(json['serverTime'] as String),
  members: (json['members'] as List<dynamic>)
      .map((e) => TeamMemberDto.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$TeamDtoToJson(TeamDto instance) => <String, dynamic>{
  'serverTime': instance.serverTime.toIso8601String(),
  'members': instance.members.map((e) => e.toJson()).toList(),
};

InvitationRequestDto _$InvitationRequestDtoFromJson(
  Map<String, dynamic> json,
) => InvitationRequestDto(
  email: json['email'] as String,
  role: json['role'] as String,
);

Map<String, dynamic> _$InvitationRequestDtoToJson(
  InvitationRequestDto instance,
) => <String, dynamic>{'email': instance.email, 'role': instance.role};

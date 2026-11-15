import 'package:dio/dio.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/dto/tenant_dtos.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/network/parse_exception.dart';

/// Origen remoto de la administración de la institución (HTTP o mock).
abstract interface class TenantRemoteDataSource {
  /// `GET /tenant/domains`.
  Future<List<InstitutionDomainDto>> domains();

  /// `POST /tenant/domains`.
  Future<InstitutionDomainDto> addDomain(AddDomainRequestDto request);

  /// `DELETE /tenant/domains/{id}`.
  Future<void> removeDomain(InstitutionDomainId id);

  /// `GET /tenant/team`.
  Future<TeamDto> team();

  /// `POST /tenant/invitations`.
  Future<TeamMemberDto> invite(InvitationRequestDto request);
}

/// Los endpoints `/tenant/*` de docs/07.
class TenantHttpDataSource implements TenantRemoteDataSource {
  const TenantHttpDataSource(this._dio);

  final Dio _dio;

  static Map<String, dynamic> _object(Object? data, String what) {
    if (data is! Map<String, dynamic>) {
      throw ParseException('$what no es un objeto.');
    }
    return data;
  }

  @override
  Future<List<InstitutionDomainDto>> domains() async {
    final response = await _dio.get<Object?>('/tenant/domains');
    final data = response.data;
    if (data is! List) {
      throw const ParseException('Los dominios no son una lista.');
    }
    return [
      for (final item in data)
        InstitutionDomainDto.fromJson(_object(item, 'Un dominio')),
    ];
  }

  @override
  Future<InstitutionDomainDto> addDomain(AddDomainRequestDto request) async {
    final response = await _dio.post<Object?>(
      '/tenant/domains',
      data: request.toJson(),
    );
    return InstitutionDomainDto.fromJson(_object(response.data, 'El dominio'));
  }

  @override
  Future<void> removeDomain(InstitutionDomainId id) async {
    await _dio.delete<Object?>('/tenant/domains/${id.value}');
  }

  @override
  Future<TeamDto> team() async {
    final response = await _dio.get<Object?>('/tenant/team');
    return TeamDto.fromJson(_object(response.data, 'El equipo'));
  }

  @override
  Future<TeamMemberDto> invite(InvitationRequestDto request) async {
    final response = await _dio.post<Object?>(
      '/tenant/invitations',
      data: request.toJson(),
    );
    return TeamMemberDto.fromJson(_object(response.data, 'La invitación'));
  }
}

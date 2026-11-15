import 'package:quadrapp_mobile/contexts/iam/domain/entities/institution_domain.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/entities/team.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/repositories/tenant_directory.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/datasources/tenant_remote_datasource.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/dto/tenant_dtos.dart';
import 'package:quadrapp_mobile/contexts/iam/infrastructure/mappers/tenant_mapper.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/network/failure_mapper.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// Los dominios de la institución (US30), sin caché: se administran.
class DomainRegistryImpl implements DomainRegistry {
  const DomainRegistryImpl({required this._remote, required this._mapper});

  final TenantRemoteDataSource _remote;
  final TenantMapper _mapper;

  @override
  Future<Result<List<InstitutionDomain>>> list() =>
      guardResult(() async => _mapper.toDomains(await _remote.domains()));

  @override
  Future<Result<InstitutionDomain>> add(DomainName name) =>
      guardResult(() async {
        final dto = await _remote.addDomain(
          AddDomainRequestDto(domain: name.value),
        );
        return _mapper.toDomain(dto);
      });

  @override
  Future<Result<void>> remove(InstitutionDomainId id) =>
      guardResult(() => _remote.removeDomain(id));
}

/// El equipo de Operación (US31).
class TeamDirectoryImpl implements TeamDirectory {
  const TeamDirectoryImpl({required this._remote, required this._mapper});

  final TenantRemoteDataSource _remote;
  final TenantMapper _mapper;

  @override
  Future<Result<Team>> team() =>
      guardResult(() async => _mapper.toTeam(await _remote.team()));

  @override
  Future<Result<InvitationReceipt>> invite(NewInvitation invitation) =>
      guardResult(() async {
        final dto = await _remote.invite(_mapper.toInvitation(invitation));
        return InvitationReceipt(member: _mapper.toMember(dto));
      });
}

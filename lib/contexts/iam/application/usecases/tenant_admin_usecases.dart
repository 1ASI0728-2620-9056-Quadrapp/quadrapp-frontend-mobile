// US30, US31
import 'package:quadrapp_mobile/contexts/iam/domain/entities/institution_domain.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/entities/team.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/repositories/tenant_directory.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';
import 'package:quadrapp_mobile/core/usecase/usecase.dart';

/// Los dominios de correo de la institución, primero los verificados.
class GetInstitutionDomains
    implements UseCase<List<InstitutionDomain>, NoParams> {
  const GetInstitutionDomains(this._registry);

  final DomainRegistry _registry;

  @override
  Future<Result<List<InstitutionDomain>>> call(NoParams params) async {
    final result = await _registry.list();
    return switch (result) {
      Err(:final failure) => Err(failure),
      Success(:final value) => Success(
        List<InstitutionDomain>.of(value)..sort((a, b) {
          if (a.isVerified != b.isVerified) return a.isVerified ? -1 : 1;
          return a.name.value.compareTo(b.name.value);
        }),
      ),
    };
  }
}

/// Agrega un dominio escrito por el administrador (US30 esc. 1 y 3). Uno con
/// forma inválida no llega al servidor.
class AddInstitutionDomain implements UseCase<InstitutionDomain, String> {
  const AddInstitutionDomain(this._registry);

  final DomainRegistry _registry;

  @override
  Future<Result<InstitutionDomain>> call(String raw) async {
    final name = DomainName.create(raw);
    return switch (name) {
      Err(:final failure) => Err(failure),
      Success(:final value) => _registry.add(value),
    };
  }
}

/// Retira un dominio (US30 esc. 2): no entran cuentas nuevas con él y las ya
/// verificadas se conservan.
class RemoveInstitutionDomain implements UseCase<void, InstitutionDomainId> {
  const RemoveInstitutionDomain(this._registry);

  final DomainRegistry _registry;

  @override
  Future<Result<void>> call(InstitutionDomainId id) => _registry.remove(id);
}

/// El equipo de Operación con sus invitaciones pendientes.
class GetTeam implements UseCase<Team, NoParams> {
  const GetTeam(this._directory);

  final TeamDirectory _directory;

  @override
  Future<Result<Team>> call(NoParams params) => _directory.team();
}

/// Invita a un administrador o un operador (US31 esc. 1).
class InviteTeamMember implements UseCase<InvitationReceipt, NewInvitation> {
  const InviteTeamMember(this._directory);

  final TeamDirectory _directory;

  @override
  Future<Result<InvitationReceipt>> call(NewInvitation invitation) =>
      _directory.invite(invitation);
}

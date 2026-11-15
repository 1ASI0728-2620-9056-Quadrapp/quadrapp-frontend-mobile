import 'package:quadrapp_mobile/contexts/iam/domain/entities/institution_domain.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/entities/team.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// Los dominios de correo de la institución de la sesión (US30). Leer lo
/// puede cualquier rol de Operación; agregar y retirar, solo el
/// administrador (`ForbiddenFailure` al operador).
abstract interface class DomainRegistry {
  /// `GET /tenant/domains`.
  Future<Result<List<InstitutionDomain>>> list();

  /// `POST /tenant/domains`: queda pendiente (US30 esc. 1). Un dominio de otra
  /// institución es un `ValidationFailure` con `errors.domain: [taken]`
  /// (409, esc. 3).
  Future<Result<InstitutionDomain>> add(DomainName name);

  /// `DELETE /tenant/domains/{id}` (US30 esc. 2).
  Future<Result<void>> remove(InstitutionDomainId id);
}

/// El equipo de Operación de la institución (US31). Leer lo puede cualquier
/// rol de Operación; invitar, solo el administrador.
abstract interface class TeamDirectory {
  /// `GET /tenant/team`.
  Future<Result<Team>> team();

  /// `POST /tenant/invitations`. Un correo fuera de los dominios verificados
  /// o ya registrado es un `ValidationFailure` con el motivo en
  /// `errors.email` (`domain` o `taken`).
  Future<Result<InvitationReceipt>> invite(NewInvitation invitation);
}

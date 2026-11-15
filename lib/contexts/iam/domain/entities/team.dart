import 'package:equatable/equatable.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/email_address.dart';
import 'package:quadrapp_mobile/contexts/iam/domain/value_objects/user_role.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/identifiers/identifiers.dart';
import 'package:quadrapp_mobile/core/result/result.dart';

/// En qué punto está una persona del equipo (docs/06 `users.status`).
enum MemberStatus {
  /// Tiene cuenta y puede entrar.
  active,

  /// Recibió la invitación y aún no la aceptó (US31 esc. 1).
  invited,
}

/// Una persona del equipo de Operación de la institución: un administrador o
/// un operador, con cuenta o con la invitación pendiente.
class TeamMember extends Equatable {
  const TeamMember({
    required this.id,
    required this.email,
    required this.role,
    required this.status,
    this.fullName,
    this.invitationExpiresAt,
  });

  final UserId id;
  final EmailAddress email;

  /// `admin` u `operator`.
  final UserRole role;
  final MemberStatus status;
  final String? fullName;

  /// Vence la invitación (UTC); solo si está invitada.
  final DateTime? invitationExpiresAt;

  bool get isInvited => status == MemberStatus.invited;

  /// ¿Venció la invitación a la hora [now] del servidor? (US31 esc. 3).
  bool invitationExpired(DateTime now) {
    final expires = invitationExpiresAt;
    return isInvited && expires != null && !now.isBefore(expires);
  }

  @override
  List<Object?> get props => [
    id.value,
    email,
    role,
    status,
    fullName,
    invitationExpiresAt,
  ];
}

/// El equipo de Operación de la institución, con la hora del servidor a la
/// que se leyó (para saber si una invitación venció).
class Team extends Equatable {
  Team({required List<TeamMember> members, required this.serverTime})
    : members = List.unmodifiable(
        List<TeamMember>.of(members)..sort(_order),
      );

  /// Primero quienes tienen cuenta (administradores antes que operadores),
  /// después las invitaciones; dentro de cada grupo, por nombre o correo.
  static int _order(TeamMember a, TeamMember b) {
    int rank(TeamMember m) =>
        (m.isInvited ? 2 : 0) + (m.role == UserRole.admin ? 0 : 1);
    final byRank = rank(a).compareTo(rank(b));
    if (byRank != 0) return byRank;
    String key(TeamMember m) => (m.fullName ?? m.email.value).toLowerCase();
    return key(a).compareTo(key(b));
  }

  final List<TeamMember> members;
  final DateTime serverTime;

  int get activeCount => members.where((m) => !m.isInvited).length;
  int get pendingCount => members.where((m) => m.isInvited).length;

  @override
  List<Object?> get props => [members, serverTime];
}

/// Qué falta para que una invitación sea válida.
enum InvitationError {
  /// El correo no tiene forma de correo.
  invalidEmail,

  /// El rol no es de Operación (solo se invita a administradores y
  /// operadores).
  invalidRole,
}

/// Una invitación por enviar (US31 esc. 1): el correo institucional y el rol.
class NewInvitation extends Equatable {
  const NewInvitation._({required this.email, required this.role});

  /// La invitación, o `ValidationFailure` con el motivo en `errors`.
  static Result<NewInvitation> create({
    required String email,
    required UserRole role,
  }) {
    final errors = validate(email: email, role: role);
    if (errors.isNotEmpty) {
      return Err(
        ValidationFailure('La invitación no es válida.', {
          for (final error in errors)
            switch (error) {
              InvitationError.invalidEmail => 'email',
              InvitationError.invalidRole => 'role',
            }: [
              error.name,
            ],
        }),
      );
    }
    return Success(
      NewInvitation._(
        email: EmailAddress.create(email).valueOrNull!,
        role: role,
      ),
    );
  }

  /// Los motivos por los que no sería válida (vacío si lo es).
  static Set<InvitationError> validate({
    required String email,
    required UserRole role,
  }) => {
    if (EmailAddress.create(email).failureOrNull != null)
      InvitationError.invalidEmail,
    if (!role.isOperations) InvitationError.invalidRole,
  };

  final EmailAddress email;
  final UserRole role;

  @override
  List<Object?> get props => [email, role];
}

/// La invitación quedó registrada (US31 esc. 1): su vigencia.
class InvitationReceipt extends Equatable {
  const InvitationReceipt({required this.member});

  /// La persona invitada, ya como «invitación pendiente».
  final TeamMember member;

  @override
  List<Object?> get props => [member];
}

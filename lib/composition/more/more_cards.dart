// US20, US30, US31, US35
import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/composition/more/calendar_labels.dart';
import 'package:quadrapp_mobile/contexts/iam/iam.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';

/// Encabezado de tarjeta: título y, a la derecha, una acción opcional.
class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.title, this.action, this.onAction});

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final action = this.action;
    final onAction = this.onAction;
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
        ),
        if (action != null && onAction != null)
          QaButton(
            label: action,
            variant: QaButtonVariant.text,
            onPressed: onAction,
          ),
      ],
    );
  }
}

/// Una línea atenuada con ícono (notas de permisos y faltantes).
class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.qaColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: colors.onSurfaceMuted),
        const SizedBox(width: QaSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceMuted),
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------- dispositivos

/// El acceso a Dispositivos desde Más.
class DevicesEntryCard extends StatelessWidget {
  const DevicesEntryCard({required this.onOpen, super.key});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.qaColors;
    final theme = Theme.of(context);
    return QaCard(
      onTap: onOpen,
      semanticLabel: '${l10n.devices_title}. ${l10n.more_devicesHint}',
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.mint,
              borderRadius: QaRadii.controlRadius,
            ),
            child: Padding(
              padding: const EdgeInsets.all(QaSpacing.sm),
              child: Icon(Icons.sensors_rounded, color: colors.onMint),
            ),
          ),
          const SizedBox(width: QaSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.devices_title, style: theme.textTheme.titleMedium),
                Text(
                  l10n.more_devicesHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: colors.primary),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------- calendario

/// Calendario del campus (US35): periodos académicos y eventos de los
/// próximos días, cada uno con su fecha, horario o tipo y alcance. Ambos
/// roles lo administran.
class CalendarCard extends StatelessWidget {
  const CalendarCard({
    required this.events,
    required this.onAdd,
    required this.onOpen,
    this.limit = 4,
    this.onShowAll,
    super.key,
  });

  /// `null` si no llegó.
  final List<CalendarEvent>? events;
  final VoidCallback onAdd;
  final ValueChanged<CalendarEvent> onOpen;

  /// Cuántas filas se muestran; `null`, todas.
  final int? limit;
  final VoidCallback? onShowAll;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.qaColors;
    final events = this.events;
    final shown = events == null || limit == null
        ? events
        : events.take(limit!).toList();

    return QaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardHeader(
            title: l10n.more_calendarTitle,
            action: l10n.more_addEvent,
            onAction: onAdd,
          ),
          const SizedBox(height: QaSpacing.sm),
          if (events == null)
            _Note(
              icon: Icons.cloud_off_rounded,
              text: l10n.more_calendarUnavailable,
            )
          else if (events.isEmpty)
            _Note(
              icon: Icons.event_available_outlined,
              text: l10n.more_noEvents,
            )
          else ...[
            for (final (i, event) in shown!.indexed) ...[
              if (i > 0) const SizedBox(height: QaSpacing.xs),
              _EventRow(event: event, onTap: () => onOpen(event)),
            ],
            if (onShowAll != null && shown.length < events.length)
              Align(
                alignment: Alignment.centerLeft,
                child: QaButton(
                  label: l10n.more_showAllEvents(events.length),
                  variant: QaButtonVariant.text,
                  onPressed: onShowAll,
                ),
              ),
          ],
          const SizedBox(height: QaSpacing.sm),
          Text(
            l10n.more_calendarNote,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event, required this.onTap});

  final CalendarEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.qaColors;
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).languageCode;
    final badge = eventBadge(event, locale);
    final detail = eventDetail(l10n, event);
    return Semantics(
      button: true,
      label: '${event.name}. $badge. $detail',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: QaRadii.controlRadius,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: QaSpacing.xs),
            child: Row(
              children: [
                Container(
                  constraints: const BoxConstraints(minWidth: 64),
                  padding: const EdgeInsets.symmetric(
                    horizontal: QaSpacing.sm,
                    vertical: QaSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: colors.mint,
                    borderRadius: QaRadii.controlRadius,
                  ),
                  child: Text(
                    badge,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colors.onMint,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: QaSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        detail,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: colors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- dominios

/// Dominios institucionales (US30): verificados o pendientes. Solo el
/// administrador agrega ([onAdd]) y retira ([onRemove]); el operador los ve.
class DomainsCard extends StatelessWidget {
  const DomainsCard({
    required this.domains,
    this.onAdd,
    this.onRemove,
    super.key,
  });

  final List<InstitutionDomain>? domains;
  final VoidCallback? onAdd;
  final ValueChanged<InstitutionDomain>? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.qaColors;
    final theme = Theme.of(context);
    final domains = this.domains;
    final onRemove = this.onRemove;
    return QaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardHeader(
            title: l10n.more_domainsTitle,
            action: l10n.more_addDomain,
            onAction: onAdd,
          ),
          const SizedBox(height: QaSpacing.xs),
          if (domains == null)
            _Note(
              icon: Icons.cloud_off_rounded,
              text: l10n.more_domainsUnavailable,
            )
          else if (domains.isEmpty)
            _Note(
              icon: Icons.alternate_email_rounded,
              text: l10n.more_noDomains,
            )
          else
            for (final domain in domains)
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 52),
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        label: [
                          domain.name.value,
                          if (domain.isVerified)
                            l10n.more_domainVerified
                          else
                            l10n.more_domainPending,
                        ].join(', '),
                        excludeSemantics: true,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: QaSpacing.xs,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                domain.name.value,
                                style: theme.textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 2),
                              _DomainStatus(verified: domain.isVerified),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (onRemove != null)
                      IconButton(
                        tooltip: l10n.more_removeDomain(domain.name.value),
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: colors.onSurfaceMuted,
                        ),
                        onPressed: () => onRemove(domain),
                      ),
                  ],
                ),
              ),
          if (onAdd == null) ...[
            const SizedBox(height: QaSpacing.sm),
            _Note(
              icon: Icons.lock_outline_rounded,
              text: l10n.more_adminOnlyDomains,
            ),
          ],
        ],
      ),
    );
  }
}

/// Verificado o pendiente, con su ícono y su texto (nunca solo color).
class _DomainStatus extends StatelessWidget {
  const _DomainStatus({required this.verified});

  final bool verified;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.qaColors;
    final color = verified ? colors.free : colors.limitedText;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          verified ? Icons.verified_outlined : Icons.hourglass_top_rounded,
          size: 16,
          color: color,
        ),
        const SizedBox(width: QaSpacing.xs),
        Text(
          verified ? l10n.more_domainVerified : l10n.more_domainPending,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ equipo

/// Equipo e invitaciones (US31): quienes tienen cuenta y las invitaciones
/// pendientes o vencidas. Solo el administrador invita ([onInvite]).
class TeamCard extends StatelessWidget {
  const TeamCard({
    required this.team,
    required this.currentEmail,
    this.onInvite,
    super.key,
  });

  final Team? team;

  /// El correo de la sesión, para marcar «Tú».
  final String currentEmail;
  final VoidCallback? onInvite;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.qaColors;
    final theme = Theme.of(context);
    final team = this.team;
    final onInvite = this.onInvite;
    return QaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardHeader(title: l10n.more_teamTitle),
          if (team == null) ...[
            const SizedBox(height: QaSpacing.sm),
            _Note(
              icon: Icons.cloud_off_rounded,
              text: l10n.more_teamUnavailable,
            ),
          ] else ...[
            Text(
              l10n.more_teamSummary(team.activeCount, team.pendingCount),
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: QaSpacing.sm),
            for (final member in team.members)
              _MemberRow(
                member: member,
                expired: member.invitationExpired(team.serverTime),
                isYou: member.email.value == currentEmail,
              ),
          ],
          const SizedBox(height: QaSpacing.md),
          if (onInvite != null)
            QaButton(
              label: l10n.more_invite,
              icon: Icons.person_add_alt_1_outlined,
              expand: true,
              onPressed: onInvite,
            )
          else
            _Note(
              icon: Icons.lock_outline_rounded,
              text: l10n.more_adminOnlyTeam,
            ),
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.expired,
    required this.isYou,
  });

  final TeamMember member;
  final bool expired;
  final bool isYou;

  static String _initials(String text) {
    final words = text
        .split(RegExp(r'[\s@._-]+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '?';
    final first = words.first[0];
    final second = words.length > 1 ? words[1][0] : '';
    return (first + second).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.qaColors;
    final theme = Theme.of(context);
    final name = member.fullName ?? member.email.value;
    final role = member.role == UserRole.admin
        ? l10n.more_roleAdmin
        : l10n.more_roleOperator;
    final (status, statusColor) = !member.isInvited
        ? (role, colors.onSurfaceMuted)
        : expired
        ? (l10n.more_invitationExpired, colors.full)
        : (l10n.more_invitationPending, colors.limitedText);
    final label = [
      name,
      if (isYou) l10n.more_you,
      if (member.isInvited) role,
      status,
    ].join(', ');
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: QaSpacing.xs),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: member.isInvited
                  ? colors.limitedFill
                  : colors.mint,
              child: Text(
                _initials(name),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: member.isInvited ? colors.limitedText : colors.onMint,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: QaSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isYou ? '$name · ${l10n.more_you}' : name,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge,
                  ),
                  if (member.isInvited)
                    Text(
                      role,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceMuted,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: QaSpacing.sm),
            if (member.isInvited)
              Icon(
                expired
                    ? Icons.history_toggle_off_rounded
                    : Icons.schedule_rounded,
                size: 16,
                color: statusColor,
              ),
            const SizedBox(width: QaSpacing.xs),
            Text(
              status,
              style: theme.textTheme.bodySmall?.copyWith(color: statusColor),
            ),
          ],
        ),
      ),
    );
  }
}

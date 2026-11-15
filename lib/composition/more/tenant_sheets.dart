// US30, US31
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/composition/sede/live_status.dart';
import 'package:quadrapp_mobile/contexts/iam/iam.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/error/failure.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';

/// El primer motivo de `errors[field]` de un 400 o 409, si lo hay.
String? _reason(Failure failure, String field) =>
    failure is ValidationFailure ? failure.errors[field]?.firstOrNull : null;

// ---------------------------------------------------------------- dominio

/// Abre «Añadir dominio» (US30 esc. 1). [onAdd] devuelve la falla si no se
/// pudo. Devuelve `true` si se agregó.
Future<bool> showAddDomainSheet(
  BuildContext context, {
  required Future<Failure?> Function(String domain) onAdd,
}) async {
  final added = await showQaBottomSheet<bool>(
    context,
    builder: (_) => _AddDomainSheet(onAdd: onAdd),
  );
  return added ?? false;
}

class _AddDomainSheet extends StatefulWidget {
  const _AddDomainSheet({required this.onAdd});

  final Future<Failure?> Function(String domain) onAdd;

  @override
  State<_AddDomainSheet> createState() => _AddDomainSheetState();
}

class _AddDomainSheetState extends State<_AddDomainSheet> {
  final TextEditingController _domain = TextEditingController();
  String? _fieldError;
  Failure? _failure;
  bool _busy = false;

  @override
  void dispose() {
    _domain.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    if (DomainName.create(_domain.text).failureOrNull != null) {
      setState(() => _fieldError = l10n.more_domainInvalid);
      return;
    }
    setState(() {
      _busy = true;
      _fieldError = null;
      _failure = null;
    });
    final failure = await widget.onAdd(_domain.text);
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop(true);
      return;
    }
    final reason = _reason(failure, 'domain');
    setState(() {
      _busy = false;
      // Los conflictos del dominio van junto al campo (US30 esc. 3).
      _fieldError = switch (reason) {
        'taken' => l10n.more_domainTaken,
        'duplicate' => l10n.more_domainDuplicate,
        'invalid' => l10n.more_domainInvalid,
        _ => null,
      };
      _failure = _fieldError == null ? failure : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final failure = _failure;
    return QaBottomSheet(
      title: l10n.more_addDomainTitle,
      subtitle: l10n.more_addDomainSubtitle,
      closeLabel: l10n.layout_close,
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          QaButton(
            label: l10n.more_addDomainSubmit,
            loadingLabel: l10n.more_saving,
            icon: Icons.add_rounded,
            expand: true,
            isLoading: _busy,
            onPressed: () => unawaited(_submit()),
          ),
          const SizedBox(height: QaSpacing.sm),
          QaButton(
            label: l10n.layout_cancel,
            variant: QaButtonVariant.text,
            expand: true,
            onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (failure != null) ...[
            QaBanner(
              kind: QaBannerKind.error,
              message: _tenantFailureText(l10n, failure),
              requestFocus: true,
            ),
            const SizedBox(height: QaSpacing.lg),
          ],
          QaTextField(
            label: l10n.more_domainField,
            controller: _domain,
            hint: l10n.more_domainHint,
            helperText: l10n.more_domainHelper,
            errorText: _fieldError,
            enabled: !_busy,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => unawaited(_submit()),
          ),
          const SizedBox(height: QaSpacing.lg),
          QaBanner(
            kind: QaBannerKind.stale,
            icon: Icons.info_outline_rounded,
            message: l10n.more_domainPendingNote,
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------- invitación

/// Abre «Invitar al equipo» (US31 esc. 1). [onInvite] devuelve la falla si no
/// se pudo. Devuelve `true` si se envió.
Future<bool> showInviteSheet(
  BuildContext context, {
  required Future<Failure?> Function({
    required String email,
    required UserRole role,
  })
  onInvite,
}) async {
  final sent = await showQaBottomSheet<bool>(
    context,
    builder: (_) => _InviteSheet(onInvite: onInvite),
  );
  return sent ?? false;
}

class _InviteSheet extends StatefulWidget {
  const _InviteSheet({required this.onInvite});

  final Future<Failure?> Function({
    required String email,
    required UserRole role,
  })
  onInvite;

  @override
  State<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<_InviteSheet> {
  final TextEditingController _email = TextEditingController();
  UserRole _role = UserRole.operator;
  String? _fieldError;
  Failure? _failure;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    if (NewInvitation.validate(email: _email.text, role: _role).isNotEmpty) {
      setState(() => _fieldError = l10n.more_inviteEmailInvalid);
      return;
    }
    setState(() {
      _busy = true;
      _fieldError = null;
      _failure = null;
    });
    final failure = await widget.onInvite(email: _email.text, role: _role);
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop(true);
      return;
    }
    final reason = _reason(failure, 'email');
    setState(() {
      _busy = false;
      _fieldError = switch (reason) {
        'domain' => l10n.more_inviteEmailDomain,
        'taken' => l10n.more_inviteEmailTaken,
        'invalid' => l10n.more_inviteEmailInvalid,
        _ => null,
      };
      _failure = _fieldError == null ? failure : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;
    final failure = _failure;
    return QaBottomSheet(
      title: l10n.more_inviteTitle,
      subtitle: l10n.more_inviteSubtitle,
      closeLabel: l10n.layout_close,
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          QaButton(
            label: l10n.more_inviteSend,
            loadingLabel: l10n.more_inviteSending,
            icon: Icons.person_add_alt_1_outlined,
            expand: true,
            isLoading: _busy,
            onPressed: () => unawaited(_submit()),
          ),
          const SizedBox(height: QaSpacing.sm),
          QaButton(
            label: l10n.layout_cancel,
            variant: QaButtonVariant.text,
            expand: true,
            onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (failure != null) ...[
            QaBanner(
              kind: QaBannerKind.error,
              message: _tenantFailureText(l10n, failure),
              requestFocus: true,
            ),
            const SizedBox(height: QaSpacing.lg),
          ],
          QaTextField(
            label: l10n.more_inviteEmail,
            controller: _email,
            hint: l10n.more_inviteEmailHint,
            errorText: _fieldError,
            enabled: !_busy,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: QaSpacing.lg),
          Semantics(
            header: true,
            child: Text(
              l10n.more_inviteRole,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: QaSpacing.sm),
          for (final (role, title, help) in [
            (UserRole.admin, l10n.more_roleAdmin, l10n.more_roleAdminHelp),
            (
              UserRole.operator,
              l10n.more_roleOperator,
              l10n.more_roleOperatorHelp,
            ),
          ]) ...[
            _RoleOption(
              title: title,
              help: help,
              selected: _role == role,
              onTap: _busy ? null : () => setState(() => _role = role),
            ),
            const SizedBox(height: QaSpacing.sm),
          ],
          const SizedBox(height: QaSpacing.sm),
          QaBanner(kind: QaBannerKind.info, message: l10n.more_inviteNote),
        ],
      ),
    );
  }
}

/// Un rol elegible: título, para qué sirve y una marca de elegido (borde y
/// círculo relleno, no solo color).
class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.title,
    required this.help,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String help;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.qaColors;
    final theme = Theme.of(context);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: '$title. $help',
      excludeSemantics: true,
      child: Material(
        color: selected ? colors.mint : colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: QaRadii.controlRadius,
          side: BorderSide(
            color: selected ? colors.primary : colors.outline,
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(QaSpacing.md),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? colors.primary : colors.onSurfaceMuted,
                ),
                const SizedBox(width: QaSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        help,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _tenantFailureText(AppLocalizations l10n, Failure failure) =>
    switch (failure) {
      ForbiddenFailure() => l10n.more_forbidden,
      NetworkFailure() => loadErrorText(l10n, failure),
      _ => l10n.more_saveError,
    };

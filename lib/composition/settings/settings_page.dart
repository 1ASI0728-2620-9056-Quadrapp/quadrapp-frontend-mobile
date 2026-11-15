// US02, US03 (cerrar sesión); TS16 (rol y experiencia única)
// TODO(fase-6): idioma, preferencias de notificación y suscripciones.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quadrapp_mobile/composition/sign_out/sign_out.dart';
import 'package:quadrapp_mobile/composition/sign_out/sign_out_cubit.dart';
import 'package:quadrapp_mobile/contexts/iam/iam.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';
import 'package:quadrapp_mobile/core/view_state/view_state.dart';

/// La cuenta: la tarjeta de cuenta (correo, institución y rol) y "Sign out" con
/// confirmación que nombra la cuenta.
///
/// - En la experiencia de Operación es la pestaña Ajustes (`/ops/settings`,
///   con [tabIndex]).
/// - En la de Conductor es la pantalla Cuenta (`/account`) a la que se llega
///   desde el perfil de Inicio: lleva la flecha de volver ([onBack]) y ninguna
///   pestaña.
///
/// Estados: reposo, cerrando (botón con progreso), error con su salida y
/// cerrada (el router lleva a `/login`).
class SettingsPage extends StatelessWidget {
  const SettingsPage({
    required this.session,
    this.tabIndex,
    this.onBack,
    this.onOpenLegal,
    super.key,
  }) : assert(
         (tabIndex == null) != (onBack == null),
         'Es una pestaña (tabIndex) o una pantalla con volver (onBack).',
       );

  /// La cuenta con la sesión iniciada.
  final Session session;

  /// Posición de la pestaña en la barra inferior; `null` si no es una pestaña.
  final int? tabIndex;

  /// Volver a la pantalla de origen; `null` si es una pestaña.
  final VoidCallback? onBack;

  /// Abre el resumen de términos y privacidad; sin él, no se ofrece.
  final VoidCallback? onOpenLegal;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;

    // "Sign out" al fondo, al alcance del pulgar.
    final footer = BlocBuilder<SignOutCubit, ViewState<SignOutReport>>(
      builder: (context, state) {
        final signingOut = state is ViewLoading;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            QaBannerSlot(
              banner: state is ViewError<SignOutReport>
                  ? QaBanner(
                      kind: QaBannerKind.error,
                      message: l10n.signOut_error,
                      requestFocus: true,
                    )
                  : null,
            ),
            const SizedBox(height: QaSpacing.lg),
            QaButton(
              label: l10n.signOut_action,
              loadingLabel: l10n.signOut_signingOut,
              variant: QaButtonVariant.destructiveOutlined,
              icon: Icons.logout_rounded,
              size: QaButtonSize.large,
              isLoading: signingOut,
              expand: true,
              onPressed: () => _confirmAndSignOut(context, l10n),
            ),
          ],
        );
      },
    );

    return QaTabPage(
      tabIndex: tabIndex,
      onBack: onBack,
      backLabel: l10n.common_back,
      title: tabIndex == null ? l10n.title_account : l10n.nav_settings,
      footer: footer,
      children: [
        _AccountCard(session: session),
        if (onOpenLegal != null) ...[
          const SizedBox(height: QaSpacing.sm),
          QaButton(
            label: l10n.legal_title,
            icon: Icons.shield_outlined,
            variant: QaButtonVariant.text,
            expand: true,
            onPressed: onOpenLegal,
          ),
        ],
        const SizedBox(height: QaSpacing.lg),
        Text(
          l10n.settings_moreSoon,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceMuted,
          ),
        ),
      ],
    );
  }

  /// La confirmación nombra la cuenta que se cierra (docs/05, regla 5).
  Future<void> _confirmAndSignOut(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final cubit = context.read<SignOutCubit>();
    final confirmed = await showQaDialog(
      context,
      title: l10n.signOut_confirmTitle,
      message: l10n.signOut_confirmMessage(session.email.value),
      confirmLabel: l10n.signOut_action,
      cancelLabel: l10n.signOut_cancel,
      destructive: true,
    );
    if (confirmed) await cubit.signOut();
  }
}

/// Correo, institución y rol de la cuenta, en una sola tarjeta.
class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.session});

  final Session session;

  String _roleLabel(AppLocalizations l10n) => switch (session.role) {
    UserRole.driver => l10n.settings_roleDriver,
    UserRole.operator => l10n.settings_roleOperator,
    UserRole.admin => l10n.settings_roleAdmin,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;
    final email = session.email.value;
    final initial = email.isEmpty ? '?' : email.characters.first.toUpperCase();

    return Semantics(
      container: true,
      label: l10n.settings_accountSemantics(
        email,
        session.institution.name,
        _roleLabel(l10n),
      ),
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: QaRadii.cardRadius,
          border: Border.all(color: colors.paint),
        ),
        child: Padding(
          padding: const EdgeInsets.all(QaSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: SizedBox.square(
                      dimension: QaSpacing.huge,
                      child: Center(
                        child: Text(
                          initial,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: colors.onPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: QaSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          email,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: QaSpacing.xs),
                        Text(
                          session.institution.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: QaSpacing.lg),
              Divider(color: colors.paint),
              const SizedBox(height: QaSpacing.sm),
              // Con el texto muy grande el valor pasa a la línea de abajo.
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: QaSpacing.lg,
                children: [
                  Text(
                    l10n.settings_role,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceMuted,
                    ),
                  ),
                  Text(_roleLabel(l10n), style: theme.textTheme.titleSmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

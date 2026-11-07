// TODO(redesign): provisional hasta las vistas de Accesos, Analítica, Más y
// Dispositivos.
import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';

/// Lo que aún no está construido en Operación.
enum OpsSoon { accesses, analytics, more, devices }

/// Pantalla provisional de Operación: un estado vacío honesto con su
/// ilustración. Como pestaña lleva el avatar de la cuenta ([onOpenAccount]);
/// Dispositivos, que se abre desde otra pantalla, lleva la flecha de volver
/// ([onBack]). Más ofrece ir a Dispositivos ([onOpenDevices]).
class OperationsSoonPage extends StatelessWidget {
  const OperationsSoonPage({
    required this.kind,
    this.tabIndex,
    this.onOpenAccount,
    this.onOpenDevices,
    this.onBack,
    super.key,
  });

  final OpsSoon kind;
  final int? tabIndex;
  final VoidCallback? onOpenAccount;
  final VoidCallback? onOpenDevices;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (tab, title, message, illustration) = switch (kind) {
      OpsSoon.accesses => (
        l10n.nav_accesses,
        l10n.ops_accessesSoonTitle,
        l10n.ops_accessesSoonMessage,
        QaIllustrationKind.car,
      ),
      OpsSoon.analytics => (
        l10n.nav_analytics,
        l10n.ops_analyticsSoonTitle,
        l10n.ops_analyticsSoonMessage,
        QaIllustrationKind.parking,
      ),
      OpsSoon.more => (
        l10n.nav_more,
        l10n.ops_moreSoonTitle,
        l10n.ops_moreSoonMessage,
        QaIllustrationKind.parking,
      ),
      OpsSoon.devices => (
        l10n.nav_devices,
        l10n.ops_devicesSoonTitle,
        l10n.ops_devicesSoonMessage,
        QaIllustrationKind.sensor,
      ),
    };
    final onOpenAccount = this.onOpenAccount;
    return QaTabPage(
      tabIndex: tabIndex,
      title: tab,
      onBack: onBack,
      backLabel: onBack == null ? null : l10n.common_back,
      action: onOpenAccount == null
          ? null
          : QaTopBarAction(
              icon: Icons.account_circle_outlined,
              label: l10n.account_open,
              onPressed: onOpenAccount,
            ),
      children: [
        QaEmptyState(
          illustration: illustration,
          title: title,
          message: message,
          actionLabel: onOpenDevices == null ? null : l10n.ops_moreDevices,
          onAction: onOpenDevices,
        ),
      ],
    );
  }
}

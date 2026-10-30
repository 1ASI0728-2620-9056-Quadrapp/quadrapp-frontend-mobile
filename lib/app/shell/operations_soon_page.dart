// TODO(redesign): provisional hasta los commits de Shift, Lots y Devices.
import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/app/shell/shell_tabs.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';

/// Pantalla provisional de una pestaña de Operación (Shift, Lots o Devices):
/// un estado vacío honesto con su ilustración.
class OperationsSoonPage extends StatelessWidget {
  const OperationsSoonPage({required this.tab, super.key});

  /// Una de [OpsTab.shift], [OpsTab.lots] o [OpsTab.devices].
  final int tab;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (title, message, illustration) = switch (tab) {
      OpsTab.shift => (
        l10n.ops_shiftSoonTitle,
        l10n.ops_shiftSoonMessage,
        QaIllustrationKind.parking,
      ),
      OpsTab.lots => (
        l10n.ops_lotsSoonTitle,
        l10n.ops_lotsSoonMessage,
        QaIllustrationKind.car,
      ),
      _ => (
        l10n.ops_devicesSoonTitle,
        l10n.ops_devicesSoonMessage,
        QaIllustrationKind.sensor,
      ),
    };
    return QaTabPage(
      tabIndex: tab,
      title: OpsTab.operations[tab].label(l10n),
      children: [
        QaEmptyState(
          illustration: illustration,
          title: title,
          message: message,
        ),
      ],
    );
  }
}

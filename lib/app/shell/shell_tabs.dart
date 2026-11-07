import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';

/// Un destino de la barra inferior: su etiqueta (siempre visible) y su par de
/// íconos del mismo set, delineado cuando no está seleccionado y relleno
/// cuando sí.
class ShellTab {
  const ShellTab({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String Function(AppLocalizations l10n) label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Las pestañas de la experiencia de **Conductor** (rol `DRIVER`), en el orden
/// de sus ramas.
abstract final class AppTab {
  static const int home = 0;
  static const int zones = 1;
  static const int forecast = 2;
  static const int alerts = 3;

  static final List<ShellTab> driver = [
    ShellTab(
      label: (l10n) => l10n.nav_home,
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
    ),
    ShellTab(
      label: (l10n) => l10n.nav_zones,
      icon: Icons.map_outlined,
      selectedIcon: Icons.map,
    ),
    ShellTab(
      label: (l10n) => l10n.nav_forecast,
      icon: Icons.show_chart_rounded,
      selectedIcon: Icons.show_chart_rounded,
    ),
    ShellTab(
      label: (l10n) => l10n.nav_alerts,
      icon: Icons.notifications_outlined,
      selectedIcon: Icons.notifications,
    ),
  ];
}

/// Las pestañas de la experiencia de **Operación** (administrador de
/// universidad: roles `ADMIN` y `OPERATOR`, la misma barra), en el orden de sus
/// ramas, como el diseño. Dispositivos cuelga de Más; la cuenta, del avatar.
abstract final class OpsTab {
  static const int home = 0;
  static const int zones = 1;
  static const int accesses = 2;
  static const int analytics = 3;
  static const int more = 4;

  static final List<ShellTab> operations = [
    ShellTab(
      label: (l10n) => l10n.nav_home,
      icon: Icons.space_dashboard_outlined,
      selectedIcon: Icons.space_dashboard,
    ),
    ShellTab(
      label: (l10n) => l10n.nav_zones,
      icon: Icons.local_parking_outlined,
      selectedIcon: Icons.local_parking,
    ),
    ShellTab(
      label: (l10n) => l10n.nav_accesses,
      icon: Icons.door_front_door_outlined,
      selectedIcon: Icons.door_front_door,
    ),
    ShellTab(
      label: (l10n) => l10n.nav_analytics,
      icon: Icons.insights_outlined,
      selectedIcon: Icons.insights,
    ),
    ShellTab(
      label: (l10n) => l10n.nav_more,
      icon: Icons.more_horiz_rounded,
      selectedIcon: Icons.more_horiz_rounded,
    ),
  ];
}

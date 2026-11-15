// US20, TS10
import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/composition/arrival/lot_age_text.dart';
import 'package:quadrapp_mobile/composition/devices/device_labels.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/parking_sensing.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';

/// Encabezado de tarjeta: título y, a la derecha, una marca opcional.
class _CardHeader extends StatelessWidget {
  const _CardHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final trailing = this.trailing;
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: QaSpacing.sm),
          trailing,
        ],
      ],
    );
  }
}

/// Una línea con ícono y texto en un tono (nunca solo color).
class DeviceToneLine extends StatelessWidget {
  const DeviceToneLine({
    required this.icon,
    required this.text,
    required this.color,
    super.key,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: QaSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------- salud

/// Salud del estacionamiento (US20): sensores operativos y gateways en
/// línea, con cuántos no reportan, y los sensores con batería baja. Es de
/// solo lectura: registrar y dar de baja es de la plataforma.
class DevicesHealthCard extends StatelessWidget {
  const DevicesHealthCard({
    required this.inventory,
    required this.lotName,
    required this.clock,
    super.key,
  });

  final DeviceInventory inventory;
  final String lotName;
  final Clock clock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.qaColors;
    final theme = Theme.of(context);
    final live = inventory.devices.where((d) => !d.isDecommissioned).toList();
    final sensors = live.where((d) => d.type != DeviceType.gateway).toList();
    final gateways = live.where((d) => d.type == DeviceType.gateway).toList();
    final sensorsOk = sensors.where((d) => d.isOperational).length;
    final sensorsDown = sensors
        .where((d) => d.status == DeviceStatus.unreachable)
        .length;
    final gatewaysOk = gateways.where((d) => d.isOperational).length;
    final gatewaysDown = gateways.length - gatewaysOk;
    final lowBattery = sensors
        .where(
          (d) =>
              d.status == DeviceStatus.lowBattery ||
              (d.batteryPct != null && d.batteryPct! < lowBatteryPct),
        )
        .length;
    final readAge = clock.monotonic() - inventory.receivedAt;

    Widget stat(int value, String label, String spoken) => Expanded(
      child: Semantics(
        label: spoken,
        excludeSemantics: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$value',
              style: theme.textTheme.displaySmall?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: QaSpacing.xs),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceMuted,
              ),
            ),
          ],
        ),
      ),
    );

    return QaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardHeader(
            title: l10n.devices_healthTitle(lotName),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.lock_outline_rounded,
                  size: 16,
                  color: colors.primary,
                ),
                const SizedBox(width: QaSpacing.xs),
                Text(
                  l10n.devices_readOnly,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: QaSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              stat(
                sensorsOk,
                l10n.devices_sensorsActive(sensorsDown),
                l10n.devices_sensorsActiveSpoken(sensorsOk, sensorsDown),
              ),
              const SizedBox(width: QaSpacing.lg),
              stat(
                gatewaysOk,
                l10n.devices_gatewaysOnline(gatewaysDown),
                l10n.devices_gatewaysOnlineSpoken(gatewaysOk, gatewaysDown),
              ),
            ],
          ),
          if (lowBattery > 0) ...[
            const SizedBox(height: QaSpacing.md),
            DeviceToneLine(
              icon: Icons.battery_alert_rounded,
              text: l10n.devices_lowBatteryCount(lowBattery, lowBatteryPct),
              color: colors.limitedText,
            ),
          ],
          const SizedBox(height: QaSpacing.sm),
          Text(
            l10n.devices_readAgo(lotAgeText(l10n, readAge)),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}

// --------------------------------------------------------------- incidencia

/// Un gateway que no reporta (US20 esc. 2): sus sensores quedan sin datos. La
/// universidad no lo repara: lo reporta a soporte.
class GatewayIncidentCard extends StatelessWidget {
  const GatewayIncidentCard({
    required this.inventory,
    required this.gateway,
    required this.clock,
    required this.onReport,
    super.key,
  });

  final DeviceInventory inventory;
  final Device gateway;
  final Clock clock;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.qaColors;
    final theme = Theme.of(context);
    final status = gateway.status;
    return QaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardHeader(
            title: l10n.devices_gatewayTitle(gateway.hardwareId),
            trailing: QaStatusChip(
              tone: deviceTone(status),
              label: deviceStatusLabel(l10n, status),
            ),
          ),
          const SizedBox(height: QaSpacing.sm),
          Text(
            deviceDetail(l10n, inventory, gateway, clock),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceMuted,
            ),
          ),
          const SizedBox(height: QaSpacing.md),
          QaBanner(
            kind: QaBannerKind.error,
            message: status == DeviceStatus.unreachable
                ? l10n.devices_gatewayDown
                : l10n.devices_gatewayLowBattery,
            actionLabel: l10n.devices_report,
            onAction: onReport,
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------- listas

/// Un dispositivo en una lista: título, batería y última comunicación, y su
/// estado con ícono y texto.
class DeviceRow extends StatelessWidget {
  const DeviceRow({
    required this.inventory,
    required this.device,
    required this.clock,
    super.key,
  });

  final DeviceInventory inventory;
  final Device device;
  final Clock clock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.qaColors;
    final theme = Theme.of(context);
    final title = deviceTitle(l10n, device);
    final detail = deviceDetail(l10n, inventory, device, clock);
    final status = deviceStatusLabel(l10n, device.status);
    return Semantics(
      label: '$title. $detail. $status',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: QaSpacing.sm),
        child: Row(
          children: [
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
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: QaSpacing.sm),
            QaStatusChip(tone: deviceTone(device.status), label: status),
          ],
        ),
      ),
    );
  }
}

/// Una lista de dispositivos en una tarjeta, con divisores. Muestra hasta
/// [limit] y, si hay más, la acción [moreLabel].
class DeviceListCard extends StatelessWidget {
  const DeviceListCard({
    required this.inventory,
    required this.devices,
    required this.clock,
    this.title,
    this.limit,
    this.moreLabel,
    this.onMore,
    super.key,
  });

  final DeviceInventory inventory;
  final List<Device> devices;
  final Clock clock;
  final String? title;
  final int? limit;
  final String? moreLabel;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final colors = context.qaColors;
    final title = this.title;
    final shown = limit == null ? devices : devices.take(limit!).toList();
    final more = moreLabel;
    return QaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null) ...[
            _CardHeader(title: title),
            const SizedBox(height: QaSpacing.xs),
          ],
          for (final (i, device) in shown.indexed) ...[
            if (i > 0) Divider(height: 1, color: colors.outline),
            DeviceRow(inventory: inventory, device: device, clock: clock),
          ],
          if (more != null && onMore != null && shown.length < devices.length)
            Align(
              alignment: Alignment.centerLeft,
              child: QaButton(
                label: more,
                variant: QaButtonVariant.text,
                onPressed: onMore,
              ),
            ),
        ],
      ),
    );
  }
}

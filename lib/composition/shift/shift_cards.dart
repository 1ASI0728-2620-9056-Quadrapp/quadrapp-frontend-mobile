// US29, TS17, US20
import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/composition/arrival/lot_age_text.dart';
import 'package:quadrapp_mobile/composition/shift/shift_console.dart';
import 'package:quadrapp_mobile/composition/shift/shift_overview.dart';
import 'package:quadrapp_mobile/contexts/parking_sensing/parking_sensing.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';
import 'package:quadrapp_mobile/core/time/app_time_formatter.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';

/// Encabezado de una tarjeta de la consola: el título y, a la derecha, un
/// enlace o una marca opcional.
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

/// Una línea de estado con su ícono y su texto en el tono dado (nunca solo
/// color).
class _ToneLine extends StatelessWidget {
  const _ToneLine({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: QaSpacing.sm),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------- aforo

/// Aforo (US29 esc. 1 y 3): libres, ocupados y desconocidos, la barra
/// segmentada, la ocupación sin los desconocidos y la antigüedad del dato.
class ShiftCapacityCard extends StatelessWidget {
  const ShiftCapacityCard({
    required this.overview,
    required this.clock,
    super.key,
  });

  final ShiftOverview overview;
  final Clock clock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;
    final stacked = MediaQuery.textScalerOf(context).scale(16) >= 22;
    final stale = overview.freshness.isStale(clock);
    final age = lotAgeText(l10n, overview.freshness.age(clock));
    final fraction = overview.occupancyFraction;

    final stats = [
      _Stat(
        label: l10n.shift_free,
        value: overview.free,
        tone: QaTone.free,
      ),
      _Stat(
        label: l10n.shift_occupied,
        value: overview.occupied,
        tone: QaTone.occupied,
      ),
      _Stat(
        label: l10n.shift_unknown,
        value: overview.unknown,
        tone: QaTone.unknown,
      ),
    ];

    return QaCard(
      borderColor: stale ? colors.limited : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardHeader(title: l10n.shift_capacityTitle(overview.capacity)),
          const SizedBox(height: QaSpacing.xs),
          QaFreshnessLabel(
            label: l10n.shift_updated(age),
            isStale: stale,
          ),
          const SizedBox(height: QaSpacing.lg),
          if (stacked)
            for (var i = 0; i < stats.length; i++) ...[
              if (i > 0) const SizedBox(height: QaSpacing.md),
              stats[i],
            ]
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [for (final stat in stats) Expanded(child: stat)],
            ),
          const SizedBox(height: QaSpacing.lg),
          QaOccupancyBar(
            free: overview.free,
            occupied: overview.occupied,
            unknown: overview.unknown,
          ),
          const SizedBox(height: QaSpacing.md),
          Text(
            fraction == null
                ? l10n.shift_occupancyNoData
                : l10n.shift_occupancyLine((fraction * 100).round()),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.tone});

  final String label;
  final int value;
  final QaTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.qaColors;
    // Una cifra en cero no se resalta con el color de su tono.
    final color = value == 0 ? colors.onSurfaceMuted : colors.accent(tone);
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              QaToneGlyph(tone: tone, size: 12),
              const SizedBox(width: QaSpacing.xs + 2),
              Flexible(
                child: Text(
                  '$value',
                  style: theme.textTheme.displaySmall?.copyWith(color: color),
                ),
              ),
            ],
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
    );
  }
}

// -------------------------------------------------------------- saturación

/// Saturación prevista (US29 esc. 2): el momento y la ocupación prevista, que
/// no se prevé, o que el pronóstico no está disponible (TS17 esc. 3), que no
/// es lo mismo.
class ShiftSaturationCard extends StatelessWidget {
  const ShiftSaturationCard({
    required this.overview,
    required this.clock,
    super.key,
  });

  final ShiftOverview overview;
  final Clock clock;

  static const AppTimeFormatter _time = AppTimeFormatter();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;
    final locale = Localizations.localeOf(context).languageCode;
    final saturation = overview.saturation;

    final Widget body;
    if (overview.saturationUnavailable) {
      body = _ToneLine(
        icon: Icons.cloud_off_rounded,
        text: l10n.shift_saturationUnavailable,
        color: colors.onSurfaceMuted,
      );
    } else if (saturation == null) {
      body = _ToneLine(
        icon: Icons.check_circle_outline_rounded,
        text: l10n.shift_saturationNone,
        color: colors.accent(QaTone.free),
      );
    } else {
      final minutes = _minutesUntil(saturation.expectedAt);
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: colors.fill(QaTone.limited),
              borderRadius: QaRadii.controlRadius,
            ),
            child: Padding(
              padding: const EdgeInsets.all(QaSpacing.sm + 2),
              child: Icon(
                Icons.warning_amber_rounded,
                size: 24,
                color: colors.accent(QaTone.limited),
              ),
            ),
          ),
          const SizedBox(width: QaSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.shift_saturationAt(
                    saturation.pct.round(),
                    _time.formatTime(saturation.expectedAt, locale),
                  ),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: QaSpacing.xs),
                Text(
                  minutes > 0
                      ? l10n.shift_saturationIn(minutes)
                      : l10n.shift_saturationSoon,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.limitedText,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return QaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardHeader(title: l10n.shift_saturationTitle),
          const SizedBox(height: QaSpacing.md),
          body,
        ],
      ),
    );
  }

  /// Minutos hasta [expectedAt] según la hora del servidor más lo
  /// transcurrido localmente (nunca el reloj del teléfono).
  int _minutesUntil(DateTime expectedAt) {
    final freshness = overview.freshness;
    final received = freshness.receivedAt;
    final elapsed = received == null
        ? Duration.zero
        : clock.monotonic() - received;
    final serverNow = freshness.serverTime.add(elapsed);
    return expectedAt.difference(serverNow).inMinutes;
  }
}

// ----------------------------------------------------------------- alertas

/// Alertas del turno: las incidencias de dispositivos que piden atención
/// (US20), con el enlace a Dispositivos.
class ShiftAlertsCard extends StatelessWidget {
  const ShiftAlertsCard({
    required this.console,
    required this.clock,
    required this.onOpenDevices,
    super.key,
  });

  final ShiftConsole console;
  final Clock clock;
  final VoidCallback onOpenDevices;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.qaColors;
    final inventory = console.devices;
    final alerts = console.alerts;

    final List<Widget> rows;
    if (inventory == null) {
      rows = [
        _ToneLine(
          icon: Icons.cloud_off_rounded,
          text: l10n.shift_alertsUnavailable,
          color: colors.onSurfaceMuted,
        ),
      ];
    } else if (alerts.isEmpty) {
      rows = [
        _ToneLine(
          icon: Icons.check_circle_outline_rounded,
          text: l10n.shift_alertsNone,
          color: colors.accent(QaTone.free),
        ),
      ];
    } else {
      rows = [
        for (final gateway in alerts.unreachableGateways)
          _AlertRow(
            tone: QaTone.full,
            icon: Icons.error_outline_rounded,
            title: l10n.shift_alertGatewayDown(gateway.hardwareId),
            detail: _gatewayDetail(l10n, inventory, gateway),
            onTap: onOpenDevices,
          ),
        if (alerts.unreachableSensors > 0)
          _AlertRow(
            tone: QaTone.limited,
            icon: Icons.sensors_off_outlined,
            title: l10n.shift_alertSensorsDown(alerts.unreachableSensors),
            detail: l10n.shift_alertSensorsDownHint,
            onTap: onOpenDevices,
          ),
        if (alerts.lowBatterySensors > 0)
          _AlertRow(
            tone: QaTone.limited,
            icon: Icons.battery_alert_outlined,
            title: l10n.shift_alertLowBattery(alerts.lowBatterySensors),
            detail: l10n.shift_alertLowBatteryHint,
            onTap: onOpenDevices,
          ),
      ];
    }

    return QaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardHeader(
            title: l10n.shift_alertsTitle,
            trailing: TextButton(
              onPressed: onOpenDevices,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, QaSpacing.minTapTarget),
              ),
              child: Text(l10n.shift_alertsSeeDevices),
            ),
          ),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const SizedBox(height: QaSpacing.sm),
            rows[i],
          ],
        ],
      ),
    );
  }

  String _gatewayDetail(
    AppLocalizations l10n,
    DeviceInventory inventory,
    Device gateway,
  ) {
    final age = inventory.lastSeenAge(gateway, clock);
    return age == null
        ? l10n.shift_alertGatewayNever
        : l10n.shift_alertGatewaySeen(lotAgeText(l10n, age));
  }
}

/// Una incidencia: fondo suave del tono, ícono, título, detalle y una flecha.
/// Toda la fila es un solo objetivo táctil que lleva a Dispositivos.
class _AlertRow extends StatelessWidget {
  const _AlertRow({
    required this.tone,
    required this.icon,
    required this.title,
    required this.detail,
    required this.onTap,
  });

  final QaTone tone;
  final IconData icon;
  final String title;
  final String detail;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.qaColors;
    final accent = colors.accent(tone);
    return Semantics(
      button: true,
      label: '$title. $detail',
      excludeSemantics: true,
      onTap: onTap,
      child: QaPressScale(
        child: Material(
          color: colors.fill(tone),
          borderRadius: QaRadii.controlRadius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(QaSpacing.md),
              child: Row(
                children: [
                  Icon(icon, size: 22, color: accent),
                  const SizedBox(width: QaSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colors.onSurface,
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
                  Icon(Icons.chevron_right_rounded, color: accent),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------- flujo

/// Flujo de entradas y salidas del periodo (US29 esc. 1): el saldo neto en
/// grande y los dos totales. Sin conteo en los accesos o sin el dato, lo dice.
class ShiftFlowCard extends StatelessWidget {
  const ShiftFlowCard({required this.overview, super.key});

  final ShiftOverview overview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;
    final flow = overview.flow;

    if (flow == null) {
      return QaCard(
        child: _ToneLine(
          icon: overview.flowUnavailable
              ? Icons.cloud_off_rounded
              : Icons.sensor_door_outlined,
          text: overview.flowUnavailable
              ? l10n.shift_flowUnavailable
              : l10n.shift_flowNone,
          color: colors.onSurfaceMuted,
        ),
      );
    }

    final net = flow.entries - flow.exits;
    final netText = net > 0 ? '+$net' : '$net';
    return Semantics(
      container: true,
      label: [
        l10n.shift_flowTitle(flow.window.inMinutes),
        l10n.shift_flowDetail(flow.entries, flow.exits),
        l10n.shift_flowNet(netText),
      ].join('. '),
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.mint,
          borderRadius: QaRadii.cardRadius,
        ),
        child: Padding(
          padding: const EdgeInsets.all(QaSpacing.lg),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.shift_flowTitle(flow.window.inMinutes),
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: colors.onMint,
                      ),
                    ),
                    const SizedBox(height: QaSpacing.xs),
                    Text(
                      l10n.shift_flowDetail(flow.entries, flow.exits),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onMint,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: QaSpacing.md),
              Text(
                netText,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: colors.onMint,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// US19, US29
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:quadrapp_mobile/composition/accesses/accesses_overview.dart';
import 'package:quadrapp_mobile/composition/arrival/lot_age_text.dart';
import 'package:quadrapp_mobile/contexts/parking_configuration/parking_configuration.dart';
import 'package:quadrapp_mobile/core/design_system/design_system.dart';
import 'package:quadrapp_mobile/core/l10n/app_localizations.dart';
import 'package:quadrapp_mobile/core/time/app_time_formatter.dart';
import 'package:quadrapp_mobile/core/time/clock.dart';

const AppTimeFormatter _time = AppTimeFormatter();

/// Encabezado de una tarjeta: el título y, a la derecha, un enlace o una
/// marca opcional.
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

/// Una línea de estado con su ícono y su texto (nunca solo color).
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

String _signed(int value) => value > 0 ? '+$value' : '$value';

// ------------------------------------------------------------------- flujo

/// Flujo en vivo (US29 esc. 1): entradas y salidas de la ventana, el saldo
/// neto y los movimientos por minuto, con la antigüedad del dato. Sin conteo
/// en los accesos o sin el dato (respuesta parcial), lo dice.
class AccessFlowCard extends StatelessWidget {
  const AccessFlowCard({
    required this.overview,
    required this.clock,
    super.key,
  });

  final AccessesOverview overview;
  final Clock clock;

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
              ? l10n.accesses_flowUnavailable
              : l10n.accesses_flowNone,
          color: colors.onSurfaceMuted,
        ),
      );
    }

    final net = _signed(flow.net);
    final freshness = overview.freshness;
    return QaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardHeader(
            title: l10n.accesses_flowTitle(flow.window.inMinutes),
            trailing: Semantics(
              label: l10n.accesses_netSpoken(net),
              excludeSemantics: true,
              child: Text(
                l10n.accesses_net(net),
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: QaSpacing.md),
          Row(
            children: [
              Expanded(
                child: _CountTile(
                  label: l10n.accesses_entries,
                  value: flow.entries,
                  icon: Icons.login_rounded,
                  background: colors.freeFill,
                  foreground: colors.free,
                ),
              ),
              const SizedBox(width: QaSpacing.md),
              Expanded(
                child: _CountTile(
                  label: l10n.accesses_exits,
                  value: flow.exits,
                  icon: Icons.logout_rounded,
                  background: colors.infoFill,
                  foreground: colors.onSurface,
                ),
              ),
            ],
          ),
          if (flow.minutes.isNotEmpty) ...[
            const SizedBox(height: QaSpacing.lg),
            _MinuteBars(minutes: flow.minutes),
          ],
          const SizedBox(height: QaSpacing.md),
          QaFreshnessLabel(
            label: l10n.lots_updatedAgo(
              lotAgeText(l10n, freshness.age(clock)),
            ),
            isStale: freshness.isStale(clock),
          ),
        ],
      ),
    );
  }
}

/// Un total del periodo sobre un fondo suave, con su ícono (no solo color).
class _CountTile extends StatelessWidget {
  const _CountTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.background,
    required this.foreground,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.qaColors;
    return Semantics(
      container: true,
      label: '$label: $value',
      excludeSemantics: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          borderRadius: QaRadii.cardRadius,
        ),
        child: Padding(
          padding: const EdgeInsets.all(QaSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: foreground),
                  const SizedBox(width: QaSpacing.xs),
                  Flexible(
                    child: Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: QaSpacing.xs),
              Text(
                '$value',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Movimientos (entradas más salidas) por minuto, del más antiguo al minuto
/// en curso. Las barras son decorativas para el lector de pantalla: se anuncia
/// un resumen con el rango y el minuto con más movimiento. Sin animación.
class _MinuteBars extends StatelessWidget {
  const _MinuteBars({required this.minutes});

  final List<FlowMinute> minutes;

  static const double _height = 48;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;
    final locale = Localizations.localeOf(context).languageCode;

    var busiest = minutes.first;
    for (final minute in minutes) {
      if (minute.movements > busiest.movements) busiest = minute;
    }
    final top = math.max(1, busiest.movements);
    final first = _time.formatTime(minutes.first.start, locale);
    final last = _time.formatTime(minutes.last.start, locale);

    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: colors.onSurfaceMuted,
    );
    return Semantics(
      container: true,
      label: l10n.accesses_chartSpoken(
        first,
        last,
        busiest.movements,
        _time.formatTime(busiest.start, locale),
      ),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: _height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < minutes.length; i++) ...[
                  if (i > 0) const SizedBox(width: 3),
                  Expanded(
                    child: _Bar(
                      // Un minuto sin movimiento deja una marca mínima.
                      height: minutes[i].movements == 0
                          ? 3
                          : math.max(
                              6,
                              _height * minutes[i].movements / top,
                            ),
                      color: minutes[i].movements == 0
                          ? colors.paint
                          : colors.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: QaSpacing.xs),
          Row(
            children: [
              Text(first, style: labelStyle),
              const Spacer(),
              Text(l10n.accesses_chartNow(last), style: labelStyle),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.height, required this.color});

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
      ),
    );
  }
}

// ----------------------------------------------------------------- accesos

(QaTone, String) _statusOf(AppLocalizations l10n, AccessStatus status) =>
    switch (status) {
      AccessStatus.operational => (
        QaTone.free,
        l10n.accesses_statusOperational,
      ),
      AccessStatus.unreachable => (
        QaTone.full,
        l10n.accesses_statusUnreachable,
      ),
      AccessStatus.notCounting => (
        QaTone.occupied,
        l10n.accesses_statusNotCounting,
      ),
    };

String _typeOf(AppLocalizations l10n, AccessType type) => switch (type) {
  AccessType.entry => l10n.accesses_typeEntry,
  AccessType.exit => l10n.accesses_typeExit,
  AccessType.bidirectional => l10n.accesses_typeBoth,
};

/// Las cifras de un acceso según su tipo; sin dato vigente o sin conteo, lo
/// dice.
String _countsOf(AppLocalizations l10n, VehicleAccess access) {
  if (access.status == AccessStatus.notCounting) {
    return l10n.accesses_needsDirectional;
  }
  final entries = access.entries;
  final exits = access.exits;
  if (access.status != AccessStatus.operational ||
      (entries == null && exits == null)) {
    return l10n.accesses_noCurrentData;
  }
  final parts = [
    if (access.type != AccessType.exit)
      l10n.accesses_entriesCount(entries ?? 0),
    if (access.type != AccessType.entry) l10n.accesses_exitsCount(exits ?? 0),
  ];
  return parts.join(' · ');
}

/// Una fila con divisor inferior, como en el diseño.
class _DividedRow extends StatelessWidget {
  const _DividedRow({required this.child, required this.last});

  final Widget child;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(bottom: BorderSide(color: context.qaColors.paint)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: QaSpacing.md),
        child: child,
      ),
    );
  }
}

/// Los accesos del estacionamiento con su flujo de la ventana y su estado
/// (operativo, sin señal o sin conteo; siempre con texto).
class AccessListCard extends StatelessWidget {
  const AccessListCard({required this.accesses, super.key});

  final List<VehicleAccess> accesses;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;
    return QaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardHeader(title: l10n.accesses_listTitle),
          const SizedBox(height: QaSpacing.xs),
          if (accesses.isEmpty)
            _NoAccesses(l10n: l10n)
          else
            for (var i = 0; i < accesses.length; i++)
              _DividedRow(
                last: i == accesses.length - 1,
                child: Semantics(
                  container: true,
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              accesses[i].name,
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _countsOf(l10n, accesses[i]),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: QaSpacing.sm),
                      Builder(
                        builder: (context) {
                          final (tone, label) = _statusOf(
                            l10n,
                            accesses[i].status,
                          );
                          return QaStatusChip(tone: tone, label: label);
                        },
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _NoAccesses extends StatelessWidget {
  const _NoAccesses({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: QaSpacing.sm),
      child: QaEmptyState(
        compact: true,
        illustration: QaIllustrationKind.car,
        title: l10n.accesses_emptyTitle,
        message: l10n.accesses_emptyMessage,
      ),
    );
  }
}

// ----------------------------------------------------------- configuración

/// Una fila «rótulo · valor» de la configuración.
class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.qaColors;
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: QaSpacing.xs),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceMuted,
                ),
              ),
            ),
            const SizedBox(width: QaSpacing.sm),
            Text(
              value,
              style: theme.textTheme.titleSmall?.copyWith(
                color: valueColor ?? colors.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// La configuración propia del estacionamiento: horario, modalidad (siempre
/// gratuito) y alerta de ocupación. «Editar» solo si [onEdit] no es `null`
/// (administrador); el operador la ve como solo lectura.
class LotSettingsCard extends StatelessWidget {
  const LotSettingsCard({required this.settings, this.onEdit, super.key});

  final LotSettings settings;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;
    final onEdit = this.onEdit;
    final opensAt = settings.opensAt;
    final closesAt = settings.closesAt;

    return QaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardHeader(
            title: l10n.accesses_settingsTitle,
            trailing: onEdit == null
                ? Text(
                    l10n.accesses_readOnly,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.onSurfaceMuted,
                    ),
                  )
                : Semantics(
                    button: true,
                    label: l10n.accesses_editSpoken,
                    excludeSemantics: true,
                    child: TextButton.icon(
                      onPressed: onEdit,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, QaSpacing.minTapTarget),
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: Text(l10n.accesses_edit),
                    ),
                  ),
          ),
          const SizedBox(height: QaSpacing.xs),
          _SettingRow(
            label: l10n.accesses_schedule,
            value: opensAt == null || closesAt == null
                ? l10n.accesses_noSchedule
                : l10n.accesses_scheduleValue(opensAt.hhmm, closesAt.hhmm),
            valueColor: settings.hasSchedule ? null : colors.onSurfaceMuted,
          ),
          _SettingRow(
            label: l10n.accesses_mode,
            value: l10n.accesses_free,
            valueColor: colors.free,
          ),
          _SettingRow(
            label: l10n.accesses_threshold,
            value: l10n.accesses_percent(settings.saturationThresholdPct),
          ),
          const SizedBox(height: QaSpacing.sm),
          Text(
            onEdit == null
                ? l10n.accesses_readOnlyNote
                : l10n.accesses_settingsNote,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceMuted,
            ),
          ),
        ],
      ),
    );
  }
}

/// Los accesos registrados con su tipo y si cuentan flujo (US19 esc. 2 y 3:
/// solo cuenta un acceso con sensor que distingue la dirección).
class AccessSetupCard extends StatelessWidget {
  const AccessSetupCard({required this.accesses, super.key});

  final List<VehicleAccess> accesses;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.qaColors;
    return QaCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CardHeader(title: l10n.accesses_setupTitle),
          const SizedBox(height: QaSpacing.xs),
          if (accesses.isEmpty)
            _NoAccesses(l10n: l10n)
          else
            for (var i = 0; i < accesses.length; i++)
              _DividedRow(
                last: i == accesses.length - 1,
                child: MergeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              accesses[i].name,
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                          const SizedBox(width: QaSpacing.sm),
                          Text(
                            _typeOf(l10n, accesses[i].type),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colors.onSurfaceMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: QaSpacing.xs),
                      _ToneLine(
                        icon: accesses[i].flowCountingEnabled
                            ? Icons.swap_vert_rounded
                            : Icons.block_rounded,
                        text: accesses[i].flowCountingEnabled
                            ? l10n.accesses_countingOn
                            : l10n.accesses_countingOff,
                        color: accesses[i].flowCountingEnabled
                            ? colors.free
                            : colors.onSurfaceMuted,
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
